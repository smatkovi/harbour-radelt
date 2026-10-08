# Echte Antworten der Schnittstelle (gemessen)

Mit dem Keks `fw_login` eines angemeldeten Kontos am 2026-10-08 abgerufen,
Basis `https://dashboard.radelt.at/api/v2`.

Hier stehen **Schluessel und Typen**, keine persoenlichen Werte: Namen,
Anschrift, Mail, Kennungen und Freitexte sind weggelassen; Zahlen stehen nur,
wo sie die Form zeigen.

Das korrigiert die Vermutungen in `api.md`: die Felder heissen durchweg
**camelCase** (nicht snake_case), die Nutzlast steckt in `data`, und die
Anmeldung laeuft ueber den Keks `fw_login`, nicht ueber `Authorization: Bearer`.

## GET /person

```
person: Objekt
  id: Ganzzahl = <Kennzahl>
  email: Text
  created_at: Text
  username: leer = leer
  firstName: Text
  lastName: Text
  nickname: leer = leer
  country: Text
  city: Text
  postalCode: Text
  street: leer = leer
  houseNumber: leer = leer
  phoneNumber: leer = leer
  updated_at: Text
  dateOfBirth: leer = leer
  newsletter: Ja/Nein = False
  newsletterOrganisations: Ja/Nein = False
  rideEntryReminder: Text = 'NONE'
  state: Text
  visibleForFriends: Ja/Nein = False
  showPublicNickname: Ja/Nein = False
  familyMembers: Liste[0]
  tocAccepted: Ja/Nein = True
```

## GET /dashboard

```
personId: Ganzzahl = <Kennzahl>
firstName: Text
lastName: Text
username: Text
apiToken: Text
challenges: Objekt
  registerable: Liste[0]
  registered: Liste[0]
yearlyStatistics: Objekt
  2026: Objekt
    id: leer = None
    challenge_id: leer = None
    km_total: Ganzzahl = 0
    height_meters_total: leer = None
    km_average: Ganzzahl = 0
    kcal: Ganzzahl = 0
    co2: Ganzzahl = 0
    money_saved: Ganzzahl = 0
    physical_activity_percentage: leer = None
    number_of_people: Ganzzahl = 1
    created_at: leer = None
    months: Objekt
      2026-01-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-01-01'
        date_end: Text = '2026-01-31'
      2026-02-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-02-01'
        date_end: Text = '2026-02-28'
      2026-03-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-03-01'
        date_end: Text = '2026-03-31'
      2026-04-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-04-01'
        date_end: Text = '2026-04-30'
      2026-05-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-05-01'
        date_end: Text = '2026-05-31'
      2026-06-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-06-01'
        date_end: Text = '2026-06-30'
      2026-07-01: Objekt
        id: leer = None
        challenge_id: leer = None
        km_total: Ganzzahl = 0
        height_meters_total: leer = None
        date_start: Text = '2026-07-01'
```

## GET /bikes

```
bikes: Liste[1]
  id: Ganzzahl = <Kennzahl>
  name: Text
  entryType: Text = 'DISTANCE'
  countIntoStatistic: Ja/Nein = True
  isActive: Ja/Nein = True
  isEbike: Ja/Nein = False
  isMain: Ja/Nein = False
  canBeDeleted: Ja/Nein = False
  isBikeDeactivateable: Ja/Nein = False
```

## GET /statistics

```
yearlyStatistics: Objekt
  2026: Objekt
    id: leer = None
    challenge_id: leer = None
    km_total: Ganzzahl = 0
    height_meters_total: leer = None
    km_average: Ganzzahl = 0
    kcal: Ganzzahl = 0
    co2: Ganzzahl = 0
    m2_trees: Ganzzahl = 0
    money_saved: Ganzzahl = 0
    physical_activity_percentage: leer = None
    number_of_people: Ganzzahl = 0
    created_at: leer = None
    name: Text
    bikertype_ranking: leer = None
    bikertype_total: leer = None
challengeStatistics: leer = None
```

## GET /statistics/available

```
challengeStatistics: Objekt
  active: leer = None
  completed: leer = None
yearlyStatistics: Liste[1]
```

## GET /bikertypes

```
Liste[9]
  id: Ganzzahl = <Kennzahl>
  name: Text
  description: Text
  performanceText: Text
  image: Text
```

## GET /goals

```
selected: Liste[0]
predefined: Liste[0]
personal: Liste[0]
```

## GET /challenges/active

```
challenges: Objekt
  available: Liste[0]
  signedup: Liste[0]
```

## GET /trophies

```
Liste[0]
```

## GET /timelineevents

```
Liste[0]
```

## GET /organisations/preferred

```
organisations: Liste[0]
```

## GET /notifications

```
notifications: Liste[1]
  id: Text
  content: Text
  title: Text
  type: Text
  createdAt: Text
  readAt: Text
  additionalData: Objekt
    actionUrl: Text
```

## GET /journeylogs

```
{"success": false, "message": null, "error": "challenge_not_found"}
```

## GET /sponsors

```
Liste[11]
  name: leer = leer
  url: Text
  img: Text
```

## GET /newsevents

```
items: Liste[15]
  slug: Text
  type: Text = 'NEWS'
  url: Text
  title: Text
  description: Text
  image: Text
  datetime: Text
  sort_datetime: Text
```

