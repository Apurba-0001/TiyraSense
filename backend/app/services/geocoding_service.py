import asyncio
import re
from typing import Any, Dict, List
import httpx

from backend.app.schemas.routes import PlaceSearchResult

# Curated high-density gazetteer across all 8 North Eastern states
NER_GAZETTEER: List[Dict[str, Any]] = [
    # Assam - Major Hubs & Districts
    {"name": "Guwahati (Paltan Bazaar / ISBT)", "lat": 26.1445, "lon": 91.7362, "state": "Assam", "type": "city"},
    {"name": "Guwahati Port & Logistics Depot", "lat": 26.1820, "lon": 91.7500, "state": "Assam", "type": "hub"},
    {"name": "Jorabat Highway Junction", "lat": 26.1030, "lon": 91.8680, "state": "Assam", "type": "junction"},
    {"name": "Dispur Capital Complex", "lat": 26.1420, "lon": 91.7890, "state": "Assam", "type": "city"},
    {"name": "Silchar Transshipment Depot", "lat": 24.8333, "lon": 92.7789, "state": "Assam", "type": "hub"},
    {"name": "Jorhat Regional Hub", "lat": 26.7509, "lon": 94.2037, "state": "Assam", "type": "city"},
    {"name": "Dibrugarh Multi-Modal Center", "lat": 27.4728, "lon": 94.9120, "state": "Assam", "type": "city"},
    {"name": "Tezpur Northern Freight Hub", "lat": 26.6528, "lon": 92.7926, "state": "Assam", "type": "city"},
    {"name": "Nagaon Highway Junction", "lat": 26.3460, "lon": 92.6840, "state": "Assam", "type": "junction"},
    {"name": "Numaligarh Refinery Depot", "lat": 26.5925, "lon": 93.7431, "state": "Assam", "type": "hub"},
    {"name": "Bokakhat Transit Center", "lat": 26.6022, "lon": 93.5936, "state": "Assam", "type": "town"},
    {"name": "Kaziranga Kohora Gateway", "lat": 26.5870, "lon": 93.4110, "state": "Assam", "type": "town"},
    {"name": "Bongaigaon Logistics Depot", "lat": 26.5020, "lon": 90.5530, "state": "Assam", "type": "hub"},
    {"name": "Dhubri River Port", "lat": 26.0200, "lon": 89.9800, "state": "Assam", "type": "port"},
    {"name": "Goalpara Town Center", "lat": 26.1700, "lon": 90.6200, "state": "Assam", "type": "town"},
    {"name": "Barpeta Town", "lat": 26.3200, "lon": 91.0000, "state": "Assam", "type": "town"},
    {"name": "Nalbari Commercial Center", "lat": 26.4400, "lon": 91.4400, "state": "Assam", "type": "town"},
    {"name": "North Lakhimpur Hub", "lat": 27.2300, "lon": 94.1000, "state": "Assam", "type": "town"},
    {"name": "Dhemaji Transit Point", "lat": 27.4800, "lon": 94.5800, "state": "Assam", "type": "town"},
    {"name": "Tinsukia Industrial Hub", "lat": 27.5000, "lon": 95.3600, "state": "Assam", "type": "hub"},
    {"name": "Sivasagar Historical Center", "lat": 26.9800, "lon": 94.6300, "state": "Assam", "type": "town"},
    {"name": "Golaghat Commercial Depot", "lat": 26.5200, "lon": 93.9700, "state": "Assam", "type": "town"},
    {"name": "Diphu (Karbi Anglong)", "lat": 25.8400, "lon": 93.4300, "state": "Assam", "type": "town"},
    {"name": "Haflong Hill Depot (Dima Hasao)", "lat": 25.1700, "lon": 93.0200, "state": "Assam", "type": "town"},
    {"name": "Badarpur Railway Junction", "lat": 24.9000, "lon": 92.6000, "state": "Assam", "type": "junction"},
    {"name": "Karimganj Border Depot", "lat": 24.8700, "lon": 92.3500, "state": "Assam", "type": "border"},
    {"name": "Hailakandi Town", "lat": 24.6800, "lon": 92.5600, "state": "Assam", "type": "town"},
    {"name": "Kokrajhar Town", "lat": 26.4000, "lon": 90.2700, "state": "Assam", "type": "town"},
    {"name": "Morigaon Commercial Center", "lat": 26.2500, "lon": 92.3400, "state": "Assam", "type": "town"},

    # Meghalaya - Hills, Passes & Border
    {"name": "Shillong Terminal Hub (Police Bazar)", "lat": 25.5788, "lon": 91.8933, "state": "Meghalaya", "type": "city"},
    {"name": "Nongpoh Transit Station", "lat": 25.9030, "lon": 91.8810, "state": "Meghalaya", "type": "town"},
    {"name": "Barapani (Umiam Lake Hub)", "lat": 25.6670, "lon": 91.9050, "state": "Meghalaya", "type": "town"},
    {"name": "Cherrapunji (Sohra Logistics)", "lat": 25.2986, "lon": 91.7378, "state": "Meghalaya", "type": "town"},
    {"name": "Mawlynnong Village", "lat": 25.2014, "lon": 91.9160, "state": "Meghalaya", "type": "village"},
    {"name": "Dawki Border Checkpost", "lat": 25.1840, "lon": 92.0160, "state": "Meghalaya", "type": "border"},
    {"name": "Jowai Transit Depot (West Jaintia)", "lat": 25.4500, "lon": 92.2000, "state": "Meghalaya", "type": "town"},
    {"name": "Khliehriat Coal Belt Hub", "lat": 25.3500, "lon": 92.3700, "state": "Meghalaya", "type": "hub"},
    {"name": "Tura Regional Depot (Garo Hills)", "lat": 25.5140, "lon": 90.2200, "state": "Meghalaya", "type": "city"},
    {"name": "Nongstoin Hill Center", "lat": 25.5200, "lon": 91.2700, "state": "Meghalaya", "type": "town"},
    {"name": "Mairang Town", "lat": 25.5600, "lon": 91.6400, "state": "Meghalaya", "type": "town"},
    {"name": "Williamnagar (East Garo Hills)", "lat": 25.6000, "lon": 90.6200, "state": "Meghalaya", "type": "town"},
    {"name": "Baghmara Border Depot", "lat": 25.1900, "lon": 90.6300, "state": "Meghalaya", "type": "border"},

    # Nagaland - Railhead & Hill Corridors
    {"name": "Dimapur Railhead Hub", "lat": 25.9068, "lon": 93.7271, "state": "Nagaland", "type": "hub"},
    {"name": "Kohima Central Depot", "lat": 25.6751, "lon": 94.1086, "state": "Nagaland", "type": "city"},
    {"name": "Mokokchung Logistics Hub", "lat": 26.3200, "lon": 94.5200, "state": "Nagaland", "type": "town"},
    {"name": "Tuensang Hill Terminal", "lat": 26.2800, "lon": 94.8300, "state": "Nagaland", "type": "town"},
    {"name": "Wokha Agricultural Depot", "lat": 26.1000, "lon": 94.2600, "state": "Nagaland", "type": "town"},
    {"name": "Zunheboto Hill Station", "lat": 25.9700, "lon": 94.5200, "state": "Nagaland", "type": "town"},
    {"name": "Mon Border Depot", "lat": 26.7500, "lon": 95.0600, "state": "Nagaland", "type": "border"},
    {"name": "Phek Town Depot", "lat": 25.6700, "lon": 94.5000, "state": "Nagaland", "type": "town"},
    {"name": "Chumukedima Highway Gateway", "lat": 25.7900, "lon": 93.7700, "state": "Nagaland", "type": "junction"},

    # Manipur - Intermodal & Trade Corridors
    {"name": "Imphal Intermodal Depot", "lat": 24.8170, "lon": 93.9368, "state": "Manipur", "type": "city"},
    {"name": "Moreh Integrated Border Post", "lat": 24.2460, "lon": 94.3050, "state": "Manipur", "type": "border"},
    {"name": "Pallel Transit Checkpoint", "lat": 24.5020, "lon": 94.0280, "state": "Manipur", "type": "junction"},
    {"name": "Churachandpur Southern Depot", "lat": 24.3300, "lon": 93.6700, "state": "Manipur", "type": "town"},
    {"name": "Thoubal Logistics Point", "lat": 24.6300, "lon": 93.9900, "state": "Manipur", "type": "town"},
    {"name": "Bishnupur Hub", "lat": 24.6300, "lon": 93.7600, "state": "Manipur", "type": "town"},
    {"name": "Ukhrul Hill Depot", "lat": 25.1100, "lon": 94.3600, "state": "Manipur", "type": "town"},
    {"name": "Senapati Highway Hub (NH-02)", "lat": 25.2600, "lon": 94.0100, "state": "Manipur", "type": "town"},
    {"name": "Tamenglong Transit Point", "lat": 24.9800, "lon": 93.4900, "state": "Manipur", "type": "town"},
    {"name": "Jiribam Rail Gateway", "lat": 24.8000, "lon": 93.1200, "state": "Manipur", "type": "border"},

    # Mizoram - Staging & Forward Posts
    {"name": "Aizawl Wholesale Staging Hub", "lat": 23.7271, "lon": 92.7176, "state": "Mizoram", "type": "city"},
    {"name": "Lunglei Southern Logistics Hub", "lat": 22.8800, "lon": 92.7300, "state": "Mizoram", "type": "town"},
    {"name": "Champhai Border Trade Center", "lat": 23.4700, "lon": 93.3300, "state": "Mizoram", "type": "border"},
    {"name": "Kolasib Northern Highway Gateway", "lat": 24.2300, "lon": 92.6800, "state": "Mizoram", "type": "town"},
    {"name": "Serchhip Commercial Depot", "lat": 23.3100, "lon": 92.8300, "state": "Mizoram", "type": "town"},
    {"name": "Saiha (Siaha) Depot", "lat": 22.4800, "lon": 92.9700, "state": "Mizoram", "type": "town"},
    {"name": "Lawngtlai Transit Point", "lat": 22.5300, "lon": 92.8900, "state": "Mizoram", "type": "town"},
    {"name": "Vairengte Inter-State Gate", "lat": 24.5100, "lon": 92.7600, "state": "Mizoram", "type": "border"},

    # Tripura - Integrated Checkposts & Industry
    {"name": "Agartala Integrated Checkpost (ICP)", "lat": 23.8315, "lon": 91.2868, "state": "Tripura", "type": "city"},
    {"name": "Dharmanagar Northern Rail Depot", "lat": 24.3700, "lon": 92.1600, "state": "Tripura", "type": "hub"},
    {"name": "Udaipur Commercial Hub", "lat": 23.5300, "lon": 91.4800, "state": "Tripura", "type": "town"},
    {"name": "Kailashahar Border Depot", "lat": 24.3300, "lon": 92.0100, "state": "Tripura", "type": "town"},
    {"name": "Belonia Southern Trade Point", "lat": 23.2500, "lon": 91.4500, "state": "Tripura", "type": "border"},
    {"name": "Ambassa Central Depot", "lat": 23.9200, "lon": 91.8500, "state": "Tripura", "type": "town"},
    {"name": "Sabroom Port Gateway (Maitri Bridge)", "lat": 23.0000, "lon": 91.7300, "state": "Tripura", "type": "border"},

    # Arunachal Pradesh - Strategic Frontiers & Passes
    {"name": "Itanagar Capital Depot", "lat": 27.0844, "lon": 93.6053, "state": "Arunachal Pradesh", "type": "city"},
    {"name": "Naharlagun Railway Terminal", "lat": 27.1000, "lon": 93.6900, "state": "Arunachal Pradesh", "type": "hub"},
    {"name": "Pasighat East Siang Center", "lat": 28.0700, "lon": 95.3300, "state": "Arunachal Pradesh", "type": "city"},
    {"name": "Tawang Frontier Staging Hub", "lat": 27.5860, "lon": 91.8670, "state": "Arunachal Pradesh", "type": "frontier"},
    {"name": "Bomdila Foothills Depot", "lat": 27.2600, "lon": 92.4200, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Dirang Valley Station", "lat": 27.3600, "lon": 92.2400, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Ziro Valley Commercial Center", "lat": 27.5900, "lon": 93.8300, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Aalo (Along) West Siang Depot", "lat": 28.1700, "lon": 94.8000, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Tezu Commercial Depot (Lohit)", "lat": 27.9200, "lon": 96.1700, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Roing Lower Dibang Valley Hub", "lat": 28.1400, "lon": 95.8400, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Namsai Golden Pagoda Hub", "lat": 27.6700, "lon": 95.8700, "state": "Arunachal Pradesh", "type": "town"},
    {"name": "Sela Pass Strategic Altitude Point", "lat": 27.5030, "lon": 92.1030, "state": "Arunachal Pradesh", "type": "pass"},

    # Sikkim - Mountain Gateways & Passes
    {"name": "Gangtok Logistics Terminal", "lat": 27.3389, "lon": 88.6065, "state": "Sikkim", "type": "city"},
    {"name": "Rangpo Border Checkpost (NH-10)", "lat": 27.1700, "lon": 88.5300, "state": "Sikkim", "type": "border"},
    {"name": "Singtam Transit Hub", "lat": 27.2300, "lon": 88.5000, "state": "Sikkim", "type": "junction"},
    {"name": "Jorethang Southern Hub", "lat": 27.1200, "lon": 88.3100, "state": "Sikkim", "type": "town"},
    {"name": "Namchi Commercial Center", "lat": 27.1600, "lon": 88.3500, "state": "Sikkim", "type": "town"},
    {"name": "Geyzing (Gyalshing) Hub", "lat": 27.2800, "lon": 88.2400, "state": "Sikkim", "type": "town"},
    {"name": "Mangan North Sikkim Base", "lat": 27.5100, "lon": 88.5300, "state": "Sikkim", "type": "frontier"},
]


class GeocodingService:
    @staticmethod
    async def search_places(query: str, limit: int = 8) -> List[PlaceSearchResult]:
        query_clean = query.strip()
        if not query_clean:
            # Return top flagship NER hubs
            return [
                PlaceSearchResult(
                    name=p["name"],
                    latitude=p["lat"],
                    longitude=p["lon"],
                    state=p["state"],
                    place_type=p["type"],
                )
                for p in NER_GAZETTEER[:limit]
            ]

        results: List[PlaceSearchResult] = []

        # 1. Exact coordinates match (e.g. "26.14, 91.73" or "26.1445,91.7362")
        coord_match = re.match(r"^(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$", query_clean)
        if coord_match:
            lat = float(coord_match.group(1))
            lon = float(coord_match.group(2))
            if -90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0:
                results.append(
                    PlaceSearchResult(
                        name=f"Custom Coordinates ({lat:.4f}, {lon:.4f})",
                        latitude=lat,
                        longitude=lon,
                        state="Custom GPS Pin",
                        place_type="coordinates",
                    )
                )
                return results

        # 2. Search local high-density NER gazetteer
        q_lower = query_clean.lower()
        exact_matches = []
        partial_matches = []

        for p in NER_GAZETTEER:
            name_lower = p["name"].lower()
            state_lower = p["state"].lower()
            if q_lower in name_lower or q_lower in state_lower:
                item = PlaceSearchResult(
                    name=p["name"],
                    latitude=p["lat"],
                    longitude=p["lon"],
                    state=p["state"],
                    place_type=p["type"],
                )
                if name_lower.startswith(q_lower):
                    exact_matches.append(item)
                else:
                    partial_matches.append(item)

        matched_local = (exact_matches + partial_matches)[:limit]
        results.extend(matched_local)

        # 3. If fewer than 3 results, query OpenStreetMap Nominatim for any arbitrary landmark/place
        if len(results) < 3:
            try:
                headers = {"User-Agent": "TiyraSense-Logistics-NER/1.0"}
                url = "https://nominatim.openstreetmap.org/search"
                params = {
                    "q": f"{query_clean}, India",
                    "format": "json",
                    "limit": limit - len(results),
                    "addressdetails": 1,
                }
                async with httpx.AsyncClient(timeout=2.0) as client:
                    resp = await client.get(url, params=params, headers=headers)
                    if resp.status_code == 200:
                        osm_data = resp.json()
                        for place in osm_data:
                            display_name = place.get("display_name", "")
                            # Shorten display name for UI clarity
                            short_name = display_name.split(",")[0].strip()
                            if len(display_name.split(",")) > 1:
                                state_or_region = display_name.split(",")[-2].strip()
                            else:
                                state_or_region = "India"
                            
                            results.append(
                                PlaceSearchResult(
                                    name=f"{short_name} ({display_name[:45]}...)" if len(display_name) > 45 else short_name,
                                    latitude=float(place["lat"]),
                                    longitude=float(place["lon"]),
                                    state=state_or_region,
                                    place_type="osm",
                                )
                            )
            except Exception:
                # Network timeout or offline - rely on gazetteer
                pass

        # 4. Fallback fallback if still empty: synthesized location in North East bounding box
        if not results:
            results.append(
                PlaceSearchResult(
                    name=f"{query_clean} (Estimated NER Location)",
                    latitude=26.1445,
                    longitude=91.7362,
                    state="Assam",
                    place_type="custom",
                )
            )

        return results[:limit]
