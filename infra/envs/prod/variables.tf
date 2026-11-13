variable "app_image" {
  description = "API image URI, ending in @sha256:<digest>."
  type        = string
}

variable "migrate_image" {
  description = "Migration image URI, ending in @sha256:<digest>."
  type        = string
}

variable "app_version" {
  description = "Version label reported by the app (APP_VERSION)."
  type        = string
}