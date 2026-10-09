# HTTP-Schnittstelle "Österreich radelt" — Referenz für den SFOS/MeeGo-Port

Stand: 2026-10-08. Quelle: Android-APK `com.jonasit.fahrradwettbewerb.oer` 10.4.2 (Flutter/Dart-AOT,
`libapp.so`) plus harmlose Live-Proben gegen `https://dashboard.radelt.at`.

**Legende der Belegstufen** (konsequent getrennt):
- `[LIVE]` = aus HTTP-Probe am 2026-10-08 gemessen.
- `[BIN]` = Zeichenkette/Symbol liegt nachweislich in `libapp.so` (Feldname ist real).
- `[VERM]` = Vermutung: Zuordnung eines Feldes zu einem Modell, Typ, Pflicht/Optional aus
  Benennung, json_serializable-Konvention und Laravel-Praxis abgeleitet, NICHT gemessen.

---

## 1. Grundlagen

| Fakt | Wert | Beleg |
|---|---|---|
| Basis-URL | `https://dashboard.radelt.at` | [BIN] (einzige radelt-API-URL im Binär) |
| Pfadpräfix | `/api/v2/` | [BIN][LIVE] |
| Server | Apache 2.4.37 (Rocky Linux), OpenSSL 1.1.1k | [LIVE] `Server:`-Kopf |
| Backend | PHP 8.2.33, Laravel (OctoberCMS-Theme auf radelt.at) | [LIVE] `X-Powered-By`, `Cache-Control: no-cache, private` |
| HTTP-Client der App | **dio** (`package:dio`) über `dart:io` HttpClient | [BIN] |
| Antwort-Typ | `application/json` (immer, auch bei Fehlern) | [LIVE] |
| CORS | `Access-Control-Allow-Origin: *` (nur auf öffentlichen Routen gesehen) | [LIVE] |
| Transfer | `Transfer-Encoding: chunked`, kein `Content-Length` | [LIVE] |

Die App-Logik liegt in `package:oesterreich_radelt/...`:
`service/network_service.dart` (Transport), `service/interceptor/header_interceptor.dart`
(Kopfzeilen + Versionsprüfung), Modelle unter `models/network/*.dart` (`*.g.dart` =
json_serializable) und `models/domain/*.dart`.

---

## 2. Anmeldung / Autorisierung  `[LIVE]` + `[BIN]`

### Mechanismus
- **Token-Auth per `Authorization: Bearer <token>`.** Belegt durch die Zeichenketten
  `authorization`, `Bearer`, `getApiToken`/`setApiToken`, `api_token`/`apiToken` in `libapp.so`.
- Der Token wird in **`flutter_secure_storage`** abgelegt (`flutter_secure_storage_service` im Binär),
  nicht in einer Datei im Klartext.
- **Kein Session-Keks nötig für die geschützten Routen.** Gemessen: die 401-Antwort von
  `GET /api/v2/dashboard` enthält **kein** `Set-Cookie`. Der Keks
  `osterreich_radelt_session=...; domain=.radelt.at; httponly; Max-Age=7200` wird nur auf den
  **öffentlichen** Routen gesetzt (login, registeruser, registerpersonaldata, forgotpassword,
  validatepostcode) — das ist Laravels Standard-Session-Middleware und für die App-Auth
  **nicht** erforderlich. Für den Port genügt der Bearer-Token; der Keks kann ignoriert werden.

### Login
`POST /api/v2/login` mit JSON-Körper `{"email": "...", "password": "..."}`  `[VERM Feldnamen; LIVE Verhalten]`
- Gemessen: leerer Körper `{}` → **HTTP 200** mit
  `{"success":false,"message":"Logindaten ungültig. Bitte melde dich neu an.","error":"authentication_failed"}`.
  (Validierung greift nicht auf Pflichtfelder, sondern läuft direkt in die Authentifizierung;
  bei Fehlschlag kommt 200 mit `success:false`.)
- Erfolgsfall `[VERM]`: Antwort enthält den Token (Feldname wahrscheinlich `api_token` oder `token`;
  beide Strings vorhanden) plus die Person. Modell `LoginResponse`/`LoginData` (siehe §5).

### Kopfzeilen, die die App sendet
- `authorization: Bearer <token>` — **einziger** nachgewiesener app-spezifischer Kopf. `[BIN]`
- `content-type: application/json`, `accept: application/json` (dio-Standard). `[BIN]`
- **Keine** eigene Versions-Kopfzeile nachweisbar. Es gibt **keinen** String `X-App-Version`/
  `x-app-version`/`App-Version` o. ä. im Binär. Die App liest nur die **Antwort**-Kopfzeile
  `x-minimum-required-app-version` (`[BIN]`, in `header_interceptor.dart`) und erzwingt ggf.
  `force_update_screen.dart`. **Korrektur zur Aufgabenannahme:** der `X-App-Version`-Kopf, den die
  Proben vorsichtshalber mitschickten, ist **nicht** das, was die echte App sendet — er ist
  unschädlich, aber zum Nachbauen nicht nötig.
- `Accept-Language` ist **nicht** als Konstante belegt (kein String `accept-language`). Sprachwahl
  läuft vermutlich serverseitig über das Personenprofil, nicht per Kopf. `[VERM]`
- User-Agent: Standard von `dart:io` (`Dart/<ver> (dart:io)`), keine eigene UA-Konstante gefunden. `[VERM]`

### Versionssperre `[LIVE]`
Auf den öffentlichen Routen liefert der Server `X-Minimum-Required-App-Version: 10.3.0`.
Auf den geschützten (401-)Routen fehlt dieser Kopf. Die App vergleicht die eigene Fassung dagegen
und zeigt sonst den Zwangs-Update-Schirm.

### Abmeldung
- Kein eigener Logout-Endpunkt in der Endpunktliste. `logout_helper.dart` im Binär `[BIN]`.
- **Abmeldung ist rein lokal** `[VERM]`: Token aus `flutter_secure_storage` löschen. Serverseitig
  kein `/logout` unter `/api/v2/` vorhanden (nicht in der Pfadliste).

---

## 3. Vollständige Endpunktliste (Methode + Auth)  `[LIVE]`

Methoden bestätigt durch Proben ohne Anmeldedaten: `405` = Methode falsch, `401` = Anmeldung nötig
(= richtige Methode), `400/404` = Methode richtig, Parameter/Körper fehlen. Je Endpunkt/Methode
höchstens eine Anfrage, dazwischen 1 s Pause.

### Öffentlich (kein Token; versionsgeprüft; setzt Session-Keks)

| Endpunkt | Methode | Probe | Bedeutung |
|---|---|---|---|
| `/api/v2/login` | POST | 200 `authentication_failed` | Anmeldung |
| `/api/v2/registeruser` | POST | 400 (fehlt `email`,`password`) | Konto anlegen (Stufe 1) |
| `/api/v2/registerpersonaldata` | POST | 404 `Fehlender Parameter personId` | Konto füllen (Stufe 2) |
| `/api/v2/forgotpassword` | GET | 400 `missing_parameter` | Passwort vergessen (Param `email` als Query) |
| `/api/v2/validatepostcode` | GET | 400 `missing_parameter` | PLZ prüfen (Param `postcode`/`country` als Query) |

> `registerpersonaldata` antwortet mit **HTTP 404** (nicht 405/422), wenn `personId` fehlt — eine
> Eigenheit des Controllers, der Endpunkt existiert und nimmt **POST**. `[LIVE]`

### Geschützt — GET (Token nötig, 401 ohne)

`dashboard`, `statistics`, `statistics/available`, `person`, `bikes`, `bikertypes`, `goals`,
`challenge`, `challenges/active`, `challenges/past`, `pois`, `pois/collect`, `journeylogs`,
`newsevents`, `notifications`, `organisations`, `organisations/preferred`, `sponsors`,
`timelineevents`, `trophies`, `friends`, `friend`, `friends/search`, `friends/getshareurl`

### Geschützt — POST

`ride/save`, `ride/update`, `bike/save`, `bikertype/select`, `goal/save`, `goal/select`,
`goal/unselect`, `challenges/signoff`, `friend/accept`, `friend/decline`, `friend/request`,
`notifications/markasread`, `notifications/updateonesignal`, `person/changepassword`

### Geschützt — PUT

`ride/track/save`, `ride/sync`, `person/update`, `journeylog/save`, `challenges/signup`,
`pois/markasfound`

### Geschützt — DELETE

`ride/delete`, `bike/delete`, `goal/delete`, `journeylog/delete`, `person/delete`, `friend/remove`

> Hinweis zur REST-Logik: `save` steht teils auf POST (`ride/save`, `bike/save`, `goal/save`),
> teils auf PUT (`journeylog/save`, `ride/track/save`). Das ist gemessen, nicht konsistent — beim
> Nachbau exakt die Methode der Tabelle verwenden.

Vollständige Rohtabelle beider Proberunden: `scratchpad/probe/` und `scratchpad/probe2/`
(`.hdr`/`.body` je Endpunkt/Methode).

---

## 4. Antwort-Umschlag (Envelope)  `[LIVE]` + `[BIN]`

Alle Antworten folgen `models/network/response.dart` (`Response`/`Data`/`ErrorResponse`):

```json
{ "success": bool, "message": string, "error": string | object, "data": object | null }
```
- `success` (bool, Pflicht) `[LIVE]`
- `message` (String, Menschentext, lokalisiert — Deutsch gemessen) `[LIVE]`
- `error`: entweder String-Code (`"authentication_failed"`, `"missing_parameter"`) **oder**
  Objekt (Laravel-Validierung: `{"password":["password muss ausgefüllt werden."], ...}`). `[LIVE]`
- `data`: Nutzlast im Erfolgsfall (bei Fehlern fehlend/null). `[VERM]` (Erfolgsfälle nicht abrufbar
  ohne Konto)

Bekannte Fehler-Codes `[LIVE]`: `authentication_failed`, `missing_parameter`.
Weitere im Binär `[BIN]`: `save_failed`/`save_faild` (Tippfehler im Original beachten),
`email_sent`.

---

## 5. Datenmodelle

Alle `_$<Klasse>ToJson` / `_$<Klasse>FromJson`-Symbole liegen im Binär (json_serializable). Die
Feldnamen unten sind als Zeichenketten in `libapp.so` nachgewiesen `[BIN]`; die **Zuordnung** zu
einer Klasse und **Typ/Pflicht** sind `[VERM]`, außer wo `[LIVE]` steht. Reihenfolge und exakte
Pflicht/Optional-Markierung je Feld sind aus dem AOT-Snapshot nicht verlustfrei rekonstruierbar
(keine ELF-Funktionssymbole, Stringpool nach Inhalt sortiert) — darum pro Modell die belegte
Feldmenge, nicht eine erfundene Signatur.

Modellliste (aus `*.g.dart`-Pfaden und `_$...ToJson`-Symbolen, Auswahl der wichtigen):
`LoginRequest, LoginResponse, LoginData, Person, Bike, Bikes, BikerType, Goal, GoalNetwork,
CreateGoalRequest, JourneyLog(Response), DashboardData, DashboardResponse, Statistic(Network),
NetworkUserStatistics, AvailableStatistics, CreateTrackingRequest, UpdateTrackingRequest,
SaveTrackRequest, TrackData, SyncRideRequest, RouteNetwork, Geometry/MultiLineGeometry,
Location, Poi(Network), PoisForBounds, PoisFoundRequest, Trophy, Campaign(Network)/Challenge,
Organization, Friend/FriendData, Notification, NewsEvents, Sponsor, RegistrationRequest,
RegistrationData, FinishRegistrationRequest, ChangePasswordRequest, ForgotPasswordRequest,
ValidatePostCodeRequest, DeleteUserRequest, TimelineItem`.

### 5.1 LoginRequest  (`POST /login`)
Belegte Felder `[BIN]`: `email` (String), `password` (String). **Beide Pflicht** `[VERM]`
(leerer Körper → `authentication_failed`, nicht Validierungsfehler).

### 5.2 LoginResponse / LoginData
Enthält Token + Person. Token-Feld: `api_token` **oder** `token` (beide Strings vorhanden) `[BIN]`,
Zuordnung `[VERM]`. Die Person kommt als eingebettetes `Person`-Objekt. Nach Login speichert die App
den Token via `setApiToken` in Secure Storage.

### 5.3 Person  (`GET /person`, Teil von LoginData)
Belegte Feldnamen `[BIN]`: `personId`, `firstName`, `lastName`, `email`, `gender`, `birthDate`,
`postcode`, `country`, `street`, `federalState`, `municipality`, `municipalityId`, `organization`,
`bikerType`, `image`, `newsletter`, `nickname`, `phone`/`phoneNumber`, `language`/`locale`,
`shareUrl`, `createdAt`, `updatedAt`.
- `personId`: Ganzzahl, Pflicht-Schlüssel (von `registerpersonaldata` verlangt, [LIVE]).
- `gender`: Kodierung unklar (nur `other` als Wert gesehen; evtl. `m`/`w`/`d` oder Ziffer). `[VERM]`
- `birthDate`: `yyyy-MM-dd` `[VERM]` (Datumsformat im Binär vorhanden).
- `federalState`: einer der 9 AT-Bundesländer (`austrian_federal_state.dart`-Enum). `[BIN]`
- `bikerType`: Verweis auf `BikerType` (siehe `/bikertypes`, `/bikertype/select`).

### 5.4 Bike  (`GET /bikes`, `POST /bike/save`, `DELETE /bike/delete`)
Belegte Felder `[BIN]`: `bikeId`, `brand`, `model`, `bikeType`, `color`, `image`, `default`
(ist-Standardrad). `isElectric`/`electric` als eigenes Feld **nicht** eindeutig belegt — E-Bike
steckt vermutlich in `bikeType`. `SaveBikeRequest` = Teilmenge davon zum Anlegen. `[VERM]`

### 5.5 Goal  (`GET /goals`, `POST /goal/save|select|unselect`, `DELETE /goal/delete`)
Belegte Felder `[BIN]`: `goalId`, `title`, `target`, `progress`, `current`, `start`/`startDate`,
`endDate`, `isActive`. `CreateGoalRequest` zum Anlegen (Teilmenge: `title`, `target`, Zeitraum). `[VERM]`

### 5.6 JourneyLog  (`GET /journeylogs`, `PUT /journeylog/save`, `DELETE /journeylog/delete`)
Belegte Felder `[BIN]`: `distance`, `comment`, `activity`, `bikeId`, `manual`, `createdAt`
(+ eine Id, Name unklar — `id` kommt nicht als Einzel-Token vor, eher `journeyLogId`/`rideId`). `[VERM]`
Fahrtenbuch-Eintrag = manuell/aggregiert erfasste Strecke (Gegenstück zur GPS-Fahrt).

### 5.7 DashboardData / Statistics  (`GET /dashboard`, `/statistics`, `/statistics/available`)
Statistik-Schlüssel sind **snake_case** (Backend-Konvention), belegt `[BIN]`:
`gefahrene_km`, `km_total`, `km_average`, `km_average_per_person`, `days_tracked`,
`days_tracked_journey`, `money_saved`, `number_of_people`, `people_total`, `pois_total`,
`pois_visited`, `organisation_count`, `organisation_name`, `organisation_ranking`,
`organisations_total`, `school_count`, `university_count`, `workplace_count`, `ranking`,
`value`, `label`, `percentage_participants`, `physical_activity_percentage`,
`height_meters_total`.
- `km_*`: Kilometer (Fließkomma). `money_saved`: Euro. `height_meters_total`: Höhenmeter. `[VERM]`
- `/statistics/available` liefert vermutlich die wählbaren Statistik-Typen (siehe
  `AvailableStatistics`). `[VERM]`
- Dashboard bündelt zusätzlich `trophies`, `goals`, `challenges` (als Listen). `[BIN]`

### 5.8 POI  (`GET /pois`, `/pois/collect`, `PUT /pois/markasfound`)
Belegte Felder `[BIN]`: `title`, `latitude`, `longitude`, `category`, `image`, `description`,
`points`, `found`, `address` (+ Id). `PoisForBounds`/`BoundsToJson` = Abfrage per Kartenausschnitt
(`Bounds`). `PoisFoundRequest` = Meldung gefundener POIs. `[VERM]`

---

## 6. Aufgezeichnete Fahrt — der Kern  `[BIN]` + `[VERM]`

Relevante Modelle (Symbole alle im Binär): `CreateTrackingRequest`, `UpdateTrackingRequest`,
`SaveTrackRequest`, `TrackData`, `SyncRideRequest`, `RouteNetwork`, `Geometry`/`MultiLineGeometry`,
`Location`, `ActivityData`, `CreateOrUpdateActivityResponse`.

Zugehörige Endpunkte (Methoden `[LIVE]`):
- `POST /api/v2/ride/save` — Fahrt anlegen (ohne GPS-Spur / manuell oder Zusammenfassung).
- `POST /api/v2/ride/update` — Fahrt ändern.
- `PUT  /api/v2/ride/track/save` — **GPS-Spur** hochladen (`SaveTrackRequest`/`TrackData`).
- `PUT  /api/v2/ride/sync` — Stapel-Abgleich offline aufgezeichneter Fahrten (`SyncRideRequest`).
- `DELETE /api/v2/ride/delete` — Fahrt löschen.

### Feldbelege `[BIN]`
- Fahrt/Aktivität: `bikeId`, `distance`, `duration`, `category`, `calories`, `challengeId`,
  `goalId`, `manual`, `activity`, `rideId`, `activityId`, `externalId`.
- Spur/Geometrie: `points`, `coordinates`, `geometry`, `route`, `tracks`, `trackData`, `offline`.
- Punkt-Ebene: `latitude`, `longitude`, `altitude`, `accuracy`, `speed`, `timestamp`.

### Rekonstruktion (als `[VERM]`, aber eng an den Belegen)
1. **Streckenformat:** Punktliste. Je Punkt `{latitude, longitude, altitude, accuracy, speed,
   timestamp}` — alle sechs als Einzel-Strings belegt, klassisches Geolocator-Muster (Flutter
   `geolocator` ist eingebunden). **Kein** `polyline`/`encodedPath` als aktiv genutztes Feld (String
   `polyline` existiert, aber eher aus der Kartenbibliothek) und **kein** GPX. Übertragung
   wahrscheinlich als JSON-Array unter `points`/`coordinates`/`geometry`.
2. **`RouteNetwork` + `MultiLineGeometry`:** vom Server **zurückgegebene** gematchte Route
   (Routing aufs Radwegnetz), nicht das, was die App sendet. `Geometry`/`MultiLineGeometry`
   (GeoJSON-artig: `type`, `coordinates`) gehört zur Antwort. `[VERM]`
3. **Einheiten:** `distance` in Metern (Geolocator liefert Meter; Statistik aggregiert zu `km_*`),
   `duration`/`speed` in SI (s bzw. m/s). `altitude`/`accuracy` in Metern. `[VERM]`
4. **Zeitstempel:** Datumsformate im Binär: `yyyy-MM-dd HH:mm:ss` (Laravel-Default) und `yyyy-MM-dd`.
   Punkt-`timestamp` vermutlich entweder ms-Epoche (Geolocator `DateTime.millisecondsSinceEpoch`)
   oder `yyyy-MM-dd HH:mm:ss`. **Nicht sicher gemessen.** `[VERM]`
5. **Doppelerkennung:** über `externalId` (Einzel-String, genau einmal im Binär belegt) —
   client-seitig erzeugte stabile Kennung je Fahrt; Server dedupliziert beim `sync`. `uuid`/`guid`
   kommen **nicht** als Einzel-Token vor, also ist `externalId` der Schlüssel. `rideId`/`activityId`
   sind die serverseitigen Kennungen (Antwort). `[VERM]`
6. **`/ride/sync` (PUT):** `SyncRideRequest` ist ein **Stapel** offline gesammelter Fahrten
   (`offline`, `tracks`/`rides`). Client lädt alle lokal gepufferten Fahrten hoch; Server legt neue
   an (nach `externalId`), ignoriert bereits bekannte und gibt die serverseitigen Ids/Statistiken
   zurück (`CreateOrUpdateActivityResponse`). Das ist der Weg für Aufzeichnungen, die ohne Netz
   entstanden sind. `[VERM]`
7. **`/ride/track/save` (PUT) vs. `/ride/save` (POST):** `track/save` lädt die reine GPS-Spur
   (`SaveTrackRequest`/`TrackData`), `ride/save` legt die Fahrt-/Aktivitätsmetadaten an
   (`CreateTrackingRequest`). Ablauf vermutlich: `ride/save` → Fahrt-Id, dann `ride/track/save` mit
   Spur, oder `ride/sync` für den Offline-Stapel. `[VERM]`

> **Offen / nicht gemessen:** exakte Pflichtfelder und genaue JSON-Verschachtelung von
> `ride/track/save` und `ride/sync`. Ohne gültigen Token nicht abrufbar; eine 401 kommt vor der
> Körpervalidierung. Zum endgültigen Festnageln: ein echtes Konto, dio-Verkehr per mitmproxy/PCAP
> mitschneiden. Bis dahin obige Rekonstruktion verwenden und serverseitige Fehlermeldungen
> (`error`-Objekt) als Korrektiv nehmen.

---

## 7. Registrierungs-Ablauf  `[LIVE]`

Zweistufig (belegt durch die Fehlertexte):
1. `POST /api/v2/registeruser` mit **Pflicht** `email`, `password` `[LIVE]`
   (leerer Körper → `{"error":{"password":[...],"email":[...]}}`). Liefert eine `personId`.
2. `POST /api/v2/registerpersonaldata` mit **Pflicht** `personId` `[LIVE]`
   (fehlt → `{"error":{"personId":"Fehlender Parameter personId."}}`) plus die Profildaten aus §5.3
   (`firstName`, `lastName`, `gender`, `birthDate`, `postcode`, `country`, `federalState`,
   `municipality(Id)`, `organization`, `bikerType`, `newsletter`, ...). `[VERM]`

Nebenrouten: `GET /api/v2/forgotpassword?email=...` (Passwort-Reset),
`GET /api/v2/validatepostcode?postcode=...` (PLZ→Gemeinde/Bundesland-Prüfung vor Stufe 2).
`/api/v2/organisations` + `/organisations/preferred` liefern die wählbaren Organisationen,
`/bikertypes` die Radler-Typen für Stufe 2.

---

## 8. Schnell-Referenz für die Implementierung

- Ein `authorization: Bearer <token>` an **jede** geschützte Anfrage, Token aus Secure Storage.
- JSON rein und raus (`application/json`), Umschlag `{success,message,error,data}` immer prüfen:
  `success==false` auch bei HTTP 200 behandeln (Login!).
- Antwortkopf `X-Minimum-Required-App-Version` auswerten → Zwangs-Update, wenn eigene Fassung kleiner.
- Fehler-`error` kann String **oder** Objekt sein → beide Fälle parsen.
- GPS-Fahrt: Punkte `{latitude,longitude,altitude,accuracy,speed,timestamp}` sammeln, stabile
  `externalId` je Fahrt erzeugen, über `ride/save`(POST)+`ride/track/save`(PUT) bzw. den
  `ride/sync`(PUT)-Stapel hochladen.
- Methoden strikt laut §3-Tabelle (POST/PUT/DELETE gemischt).

---

## 9. Belegdateien im Scratchpad
- `endpoints.txt` — 55 `/api/v2`-Pfade aus `libapp.strings`.
- `probe/` — Proberunde 1 (GET+POST, Köpfe `.hdr` + Körper `.body` je Endpunkt, 110 Dateien).
- Proberunde 2 (PUT/DELETE/PATCH für die 405/405-Fälle) nur als Statuszeilen gemessen; die
  Ergebnisse stehen in §3 (nicht als Dateien abgelegt).
- `getters.txt`, `snake_keys.txt`, `camel_mixed.txt`, `tokens.tsv` — Feldnamen-Auszüge aus dem Binär.

---

## 10. Nachtrag 08.10.2026 — am lebenden Server gemessen

Mit einem echten Konto (am selben Tag auf der Webseite angelegt, Mail bestätigt)
nachgemessen. Vier Dinge sind damit belegt und korrigieren §1 und §2:

### 10.1 Jedes Bundesland ist eine eigene Instanz

Die Anmeldung über `https://www.radelt.at/dashboard/login` antwortet mit `302` auf
**`https://wien.radelt.at/dashboard/login`** — das Konto liegt auf der Wiener Instanz.
Gemessen: `wien.radelt.at` und `vorarlberg.radelt.at` führen beide eine vollständige
`/dashboard/api/v2/`-Schnittstelle, `noe.radelt.at` leitet um (301).
**Folge für den Port:** die Basis-Adresse darf nicht fest verdrahtet sein. Im Binär der
Android-App stehen `dashboard` und `radelt.at` denn auch als getrennte Zeichenketten —
sie wird zur Laufzeit zusammengesetzt.

### 10.2 Zwei Pfade, ein Server

`https://dashboard.radelt.at/api/v2/…` und `https://<land>.radelt.at/dashboard/api/v2/…`
verhalten sich identisch (gemessen für login und statistics). `www.radelt.at/api/v2/…`
gibt es **nicht** (404).

### 10.3 Die Statuskennungen trennen Middleware und Anmelde-Code

| Aufruf | Status | Körper |
|---|---|---|
| `POST /api/v2/login` mit `{}` | **200** | `authentication_failed` |
| `POST /api/v2/login` mit richtiger Mail + Passwort | **200** | `authentication_failed` |
| `GET /api/v2/statistics` ohne Token | **401** | derselbe Körper |
| `GET /api/v2/statistics` mit Unsinns-Token | **401** | derselbe Körper |
| `POST /api/v2/registeruser` mit `{}` | **400** | `{"error":{"password":[…],"email":[…]}}` |

Daraus folgt: `/login` liegt **nicht** hinter der Auth-Middleware (die antwortet 401), der
Anmelde-Code läuft also und scheitert an den Zugangsdaten. Und `registeruser` beweist die
Feldnamen `email` und `password` für dieselbe Anwendung.

### 10.4 Was die Anmeldung *nicht* ist

Alles Folgende gemessen, alles abgelehnt mit demselben `authentication_failed`:
Feldname `email`, `username`, `login`; Passwort als Klartext, sha256, sha1, md5;
JSON und Formular; `Authorization: Basic`; mit und ohne `deviceId`/`appVersion`/`platform`;
verschachtelt als `{"user":{…}}`; auf `dashboard.radelt.at` wie auf `wien.radelt.at`.
**Auch eine gültige Web-Sitzung hilft nicht:** mit dem Keks aus dem erfolgreichen
Webformular antworten `/dashboard`, `/person` und `/bikes` weiter mit
`authentication_failed`. Die Schnittstelle nimmt ausschließlich ihren eigenen Token.

Es gibt **keine zweite Anmelderoute**: `/oauth/token`, `/api/v1/*`, `/api/v3/*`,
`/sanctum/csrf-cookie` sind alle 404.

### 10.5 Aufgeloest: der Token ist ein Keks, kein Bearer

Die Original-APK wurde unter Androidsupport auf dem jp2 installiert und dort mit
demselben Konto angemeldet -- **das ging**. Ihre abgelegten Dateien
(`/home/.appsupport/instance/<nutzer>/data/data/com.jonasit.fahrradwettbewerb.oer`)
beantworten den Rest; `tools/read-android-app.sh` liest sie aus:

* `shared_prefs/FlutterSharedPreferences.xml` enthaelt **im Klartext**
  `flutter.API_TOKEN` (60 Zeichen) und `flutter.DASHBOARD_DATA` (die zwischen-
  gespeicherte Dashboard-Antwort). Der verschluesselte Speicher
  (`FlutterSecureStorage.xml`) wird fuer anderes benutzt.
* `app_flutter/.cookies/ie0_ps1/.index` nennt den Server: **`dashboard.radelt.at`** --
  die App spricht *nicht* mit der Bundesland-Instanz, die ist nur fuer das Web.
* `.domains` enthaelt zwei Kekse: **`fw_login`** (Max-Age 31535998, also ein Jahr,
  Secure, HttpOnly) und `osterreich_radelt_session` (2 Stunden).
* **`flutter.API_TOKEN` ist Byte fuer Byte der Wert des Keks `fw_login`.**

Gemessen mit diesem Wert gegen `https://dashboard.radelt.at/api/v2`:

| Art, ihn zu schicken | Antwort |
|---|---|
| `Cookie: fw_login=<token>` | **200** mit Nutzlast |
| `Authorization: Bearer <token>` | 401 |

Damit ist §2 korrigiert: **die Plattform weist ueber den Keks `fw_login` aus.**
Der `Bearer`-Faden im Binaer gehoert zur HTTP-Bibliothek, nicht zu dieser API.

Die echten Antwortformate stehen jetzt gemessen in
[`api-echte-antworten.md`](api-echte-antworten.md) -- die Felder heissen durchweg
**camelCase** (`kmCount`, `savedCO2`, `savedMoney`, `daysTracked`, `elevation`),
nicht snake_case wie in §5.7 vermutet.

### 10.6 Die Anmeldung mit Passwort — HIER STAND EIN FALSCHER SCHLUSS

> **Berichtigt am 09.10.2026.** Der Abschnitt schloss, der Server nehme dieses
> Konto nicht an. Das war **falsch**. Es war von Anfang an ein Formatproblem:
> die Kennung heisst `user` (nicht `email`), und es fehlte die Pflicht-Signatur
> `secure`. Mit beidem meldet sich dasselbe Konto anstandslos an
> (`success:true`, am Server geprueft). Siehe **§11**. Dass auch die
> Original-APK scheiterte, hat zu dem Fehlschluss verleitet -- das hatte einen
> anderen Grund. Der folgende Abschnitt bleibt als Beleg stehen, welche
> Varianten geprueft wurden; seine Schlussfolgerung gilt nicht.

### 10.6 (alt) Die Anmeldung mit Passwort: erschöpfend geprüft

Dasselbe Konto meldet sich am **Webformular** von `dashboard.radelt.at` an
(302 auf `/dashboard/home`), an `/api/v2/login` nicht. Und: die **Original-APK**
unter Androidsupport scheitert mit demselben Konto genauso — es liegt also
nicht am Nachbau.

Geprüft und alles mit `authentication_failed` abgelehnt:

| Achse | probiert |
|---|---|
| Feldname der Kennung | `email`, `username`, `login`, `user`, `identity` |
| Wert der Kennung | Mailadresse klein und in der Schreibweise des Kontos |
| Passwortform | Klartext, sha256, sha1, md5 |
| Kodierung | JSON, Formular, Abfrageparameter, verschachtelt `{"user":{…}}` |
| Kopfzeilen | Basic-Auth, `User-Agent: Dart/…`, `Accept-Encoding: gzip`, Geräteangaben (`deviceId`, `appVersion`, `platform`) |
| Sitzung | ohne Keks, mit Sitzungskeks der Schnittstelle (über `validatepostcode` geholt), mit Sitzung des Webformulars |
| Server | `dashboard.radelt.at`, `wien.radelt.at/dashboard` |

Dazu die Belege, dass es keine andere Tür gibt: `/oauth/token`, `/api/v1/*`,
`/api/v3/*`, `/sanctum/csrf-cookie` sind 404; das Web-Dashboard ist
serverseitig gerendert und ruft `/api/v2` nie auf; `/login` antwortet **200**
(der Anmelde-Code läuft also und findet niemanden), geschützte Routen **401**,
und `registeruser` belegt namentlich die Felder `email` und `password`.

**Schluss:** der Server nimmt dieses Konto an der App-Schnittstelle nicht an.
Ein über die Webseite angelegtes Konto hat die zweite Stufe der
App-Registrierung (`registeruser` → `registerpersonaldata`) nie durchlaufen.
Wer eine Anmeldung mit Passwort braucht, legt das Konto **in der App** an;
bis dahin trägt der Keks `fw_login`, der ein Jahr gilt.

**Ein Mitschnitt der Original-App ist nicht möglich:** Dart/Flutter vertraut
nur seiner eingebauten Wurzelliste, nicht dem System- oder Apex-Speicher von
Android — eine eigene CA dort wird ignoriert (am Gerät versucht, der
Handschlag kam nie zustande).

### 10.7 Der alte Verdacht (erledigt)

Dasselbe Konto meldet sich am Webformular an (302 auf `/dashboard/home`), an der
Schnittstelle nicht. Die App-Registrierung ist zweistufig (`registeruser` →
`registerpersonaldata`); ein auf der Webseite angelegtes Konto hat die zweite Stufe
vielleicht nie durchlaufen und ist der Schnittstelle unbekannt.
**Nächster Schritt:** die Original-APK unter Androidsupport laufen lassen und dort
dasselbe Konto anmelden. Gelingt es ihr auch nicht, liegt es am Konto und nicht am
Nachbau; gelingt es, verrät ihr Zwischenspeicher (`dio_cache_interceptor` auf Hive) die
echten Formate — `tools/read-android-app.sh` liest ihn aus.


---

## 11. Die Anmeldung, aus dem Binär rekonstruiert  `[GEMESSEN]`

`blutter` (github.com/worawit/blutter) hat auf dem Baurechner das Dart-Abbild aus
`libapp.so` rekonstruiert; Dart 3.10.8 / Flutter 3.38.9. Daraus stammt der echte
Anmelde-Körper (`_$LoginRequestToJson`), **am Server bestätigt**:

```json
POST /api/v2/login
{
  "secure":          "<md5hex>",
  "user":            "<Kennung>",
  "password":        "<Passwort>",
  "oneSignalUserId": null,
  "platform":        "android",
  "appVersion":      "10.4.2",
  "language":        "de"
}
```

**Die Signatur** (`SecureRequest.createPseudoHmac`):

    secure = md5Hex( user + password + "TourDeBoedele" )

Das Salz steht wortwörtlich im Binär; die Reihenfolge `user` dann `password` ist am
Server geprüft (die andere Reihenfolge wurde ebenfalls probiert und abgelehnt).
`md5` aus `package:crypto`, Hex klein geschrieben.

**Die drei Punkte, an denen jede frühere Probe scheitern musste:**
1. Feldname **`user`** — nicht `email`. Die *Registrierung* nimmt dagegen `email`;
   die beiden Routen sind uneinheitlich, was in die Irre führte.
2. Das Pflichtfeld **`secure`**.
3. Die Zusatzfelder `platform`, `appVersion`, `language`, `oneSignalUserId`.

Die Antwort trägt `data.api_token` — bytegleich mit dem Keks `fw_login`, den der
Server im selben Atemzug setzt.

`tests/coretest.cpp` prüft das Signaturverfahren gegen einen festen Sollwert:
bricht es, bricht die Anmeldung, und zwar stillschweigend.
