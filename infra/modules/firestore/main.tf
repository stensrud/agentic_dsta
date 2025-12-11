resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = var.database_name
  location_id = var.location_id
  type        = var.database_type
}

resource "google_firestore_document" "default_campaign_setting" {
  provider    = google-beta
  project     = var.project_id
  database    = google_firestore_database.database.name
  collection  = "GoogleAdsConfig"
  document_id = "4086619433"
  fields      = <<EOF
{
  "campaigns": {
    "mapValue": {
      "fields": {
        "campaignId": {
          "integerValue": "23281245322"
        },
        "instruction": {
          "stringValue": "If the pollen count is high, pause the campaign."
        }
      }
    }
  },
  "customerId": {
    "integerValue": "4086619433"
  },
  "locations": {
    "arrayValue": {
      "values": [
        {
          "mapValue": {
            "fields": {
              "city": {
                "stringValue": "Prattville"
              },
              "city_ascii": {
                "stringValue": "Prattville"
              },
              "county_fips": {
                "integerValue": "1001"
              },
              "county_name": {
                "stringValue": "Autauga"
              },
              "lat": {
                "doubleValue": 32.4597
              },
              "lng": {
                "doubleValue": -86.4573
              },
              "population": {
                "integerValue": "38850"
              },
              "state_id": {
                "stringValue": "AL"
              },
              "state_name": {
                "stringValue": "Alabama"
              }
            }
          }
        }
      ]
    }
  }
}
EOF
  depends_on = [google_firestore_database.database]
}
