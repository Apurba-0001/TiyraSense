# Cloudinary Integration Guide — TiyraSense Evidence & Incident Photos

This guide explains how Cloudinary is integrated into **TiyraSense** for storing photo evidence from field workers and drivers, performing automated transformations (watermarks, optimization, thumbnails), and persisting metadata into Supabase PostgreSQL.

---

## 1. Architectural Flow (Direct Signed Upload)

To minimize backend bandwidth and eliminate bottlenecks in low-connectivity NER corridors, mobile and web clients upload images **directly** to Cloudinary via signed uploads:

```
[Mobile / Web Client] 
        │
        ├── 1. Request Signature ──> [Backend: POST /api/v1/evidence/signature]
        │                            (Returns: timestamp, signature, api_key, cloud_name)
        │
        ├── 2. Direct Multipart Upload ───────────────────────────────────────────┐
        │                                                                         ▼
        │                                                           [Cloudinary CDN]
        │                                                           - Applies auto-compression (q_auto, f_auto)
        │                                                           - Generates secure_url & thumbnail_url
        │                                                                         │
        ├── 3. Register Evidence Metadata <───────────────────────────────────────┘
        ▼
[Backend: POST /api/v1/evidence]
        │
        └──> [Supabase PostGIS DB: public.incident_evidence]
             - Links to field_report or incident
             - Stores camera GPS coordinates (lat/lng)
             - RLS protected
```

---

## 2. Cloudinary Account Setup Steps

1. **Sign Up / Log In to Cloudinary:**
   - Go to [https://cloudinary.com/](https://cloudinary.com/) and register for a free or team account.
   - Navigate to your **Dashboard**.
   - Note your credentials:
     - **Cloud Name** (e.g. `tiyrasense-ner`)
     - **API Key** (e.g. `784938219482912`)
     - **API Secret** (e.g. `abC123XyZ_secret_key`)

2. **Configure Upload Settings in Cloudinary Console:**
   - Go to **Settings > Upload**.
   - Under **Upload presets**, click **Add upload preset**.
   - **Preset Name**: `tiyrasense_evidence`
   - **Signing Mode**: **Signed** (recommended for secure, verified incident evidence)
   - **Folder**: `tiyrasense/evidence`
   - **Incoming Transformations**:
     - Resize & Crop: `Limit` or `Fit` to max width `1920px` (saves storage & bandwidth).
     - Format: `Auto` (`f_auto`)
     - Quality: `Auto` (`q_auto:good`)
   - Click **Save**.

3. **Watermarking & Official Verification (Optional transformation URL):**
   - Cloudinary dynamic URLs can automatically overlay an emergency timestamp and verification tag:
   ```
   https://res.cloudinary.com/<CLOUD_NAME>/image/upload/l_text:Arial_24_bold:TIYRASENSE%20VERIFIED%20EVIDENCE,co_white,g_south_east,x_20,y_20/v1/<public_id>.jpg
   ```

---

## 3. Environment Variable Configuration

Add the following keys to your `backend/.env` file:

```env
# Cloudinary Credentials (never commit secrets to Git)
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
CLOUDINARY_UPLOAD_PRESET=tiyrasense_evidence
```

---

## 4. High-Fidelity Detail-Preserving Pre-Upload Compression

To ensure fast transmission across low-connectivity 2G/3G North Eastern mountain corridors without running up bandwidth bills or choking devices, all photos undergo **smart client-side compression** via `ImageCompressorService` before reaching Cloudinary.

### How Details Remain Intact:
1. **Bicubic Resampling to 1080p/Full HD (1920px max edge):**
   - Retains sub-millimeter road crack textures, warning signs, bridge fractures, and water level markings.
   - Eliminates redundant multi-megapixel sensor noise from 48MP/108MP phone cameras.
2. **Perceptually Lossless JPEG Quality (82%–85%):**
   - High-frequency edge retention keeps road debris boundaries and text sharp while shedding 85%–92% of byte weight (e.g. from 15MB down to ~250KB–450KB).
3. **Smart Size Thresholding (No Generational Loss):**
   - Files already under 350KB are passed through untouched, preventing unnecessary re-compression.
4. **Non-Blocking Background Isolate:**
   - Runs in a background isolate via `compute()` so the camera UI and GPS tracking never drop a single frame.

---

## 5. Flutter Mobile Client Implementation

In Flutter (`mobile/`), `ImageCompressorService.compressFile()` is called automatically inside `ApiService.uploadEvidencePhotoToCloudinary(imageFile: ...)` and `HazardReportSheet`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryEvidenceService {
  final String backendUrl;
  final String authToken;

  CloudinaryEvidenceService({required this.backendUrl, required this.authToken});

  Future<Map<String, dynamic>> uploadEvidencePhoto({
    required File imageFile,
    required double latitude,
    required double longitude,
    String? incidentId,
  }) async {
    // Step 1: Request signed upload credentials from TiyraSense backend
    final sigResponse = await http.post(
      Uri.parse('$backendUrl/api/v1/evidence/signature'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'folder': 'tiyrasense/evidence',
        'tags': 'mobile_field_worker',
      }),
    );

    if (sigResponse.statusCode != 200) {
      throw Exception('Failed to obtain Cloudinary signature');
    }

    final sigData = jsonDecode(sigResponse.body);
    final String uploadUrl = sigData['upload_url'];
    final String apiKey = sigData['api_key'];
    final int timestamp = sigData['timestamp'];
    final String signature = sigData['signature'];
    final String folder = sigData['folder'];

    // Step 2: Upload multipart to Cloudinary directly
    final uploadReq = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedRes = await uploadReq.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${res.body}');
    }

    final cldData = jsonDecode(res.body);

    // Step 3: Register evidence in TiyraSense database
    final regResponse = await http.post(
      Uri.parse('$backendUrl/api/v1/evidence'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'incident_id': incidentId,
        'cloudinary_public_id': cldData['public_id'],
        'secure_url': cldData['secure_url'],
        'thumbnail_url': cldData['secure_url'],
        'width': cldData['width'],
        'height': cldData['height'],
        'bytes': cldData['bytes'],
        'format': cldData['format'],
        'camera_lat': latitude,
        'camera_lng': longitude,
      }),
    );

    return jsonDecode(regResponse.body);
  }
}
```

---

## 5. React Web Dashboard Implementation

In React (`web/`), officials or dispatchers can upload or preview incident photos:

```typescript
export async function uploadIncidentPhoto(file: File, token: string) {
  // 1. Fetch signature
  const sigRes = await fetch('/api/v1/evidence/signature', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({ folder: 'tiyrasense/evidence' })
  });
  const sig = await sigRes.json();

  // 2. Upload directly to Cloudinary
  const formData = new FormData();
  formData.append('file', file);
  formData.append('api_key', sig.api_key);
  formData.append('timestamp', String(sig.timestamp));
  formData.append('signature', sig.signature);
  formData.append('folder', sig.folder);

  const cldRes = await fetch(sig.upload_url, {
    method: 'POST',
    body: formData
  });
  const cld = await cldRes.json();

  // 3. Save to database
  const saveRes = await fetch('/api/v1/evidence', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      cloudinary_public_id: cld.public_id,
      secure_url: cld.secure_url,
      thumbnail_url: cld.secure_url,
      width: cld.width,
      height: cld.height,
      bytes: cld.bytes,
      format: cld.format
    })
  });

  return await saveRes.json();
}
```
