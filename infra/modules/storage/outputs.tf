output "bucket_names" {
  value = [for b in google_storage_bucket.buckets : b.name]
}
