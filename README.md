# Zoom Customer Analytics - Bronze Layer

This repository contains DBT models for transforming raw Zoom data into the bronze layer.

## Project Structure

- `models/bronze/`: Contains all bronze layer models
- `models/sources.yml`: Defines source tables in the raw layer
- `macros/`: Contains helper macros for auditing and logging

## Models

1. `audit_log`: Tracks processing of all models
2. `bz_users`: Bronze layer for Zoom users
3. `bz_meetings`: Bronze layer for Zoom meetings
4. `bz_participants`: Bronze layer for Zoom meeting participants
5. `bz_feature_usage`: Bronze layer for Zoom feature usage
6. `bz_webinars`: Bronze layer for Zoom webinars
7. `bz_support_tickets`: Bronze layer for Zoom support tickets
8. `bz_licenses`: Bronze layer for Zoom licenses
9. `bz_billing_events`: Bronze layer for Zoom billing events

## Transformation Logic

All models follow a 1:1 mapping from raw to bronze with the addition of audit columns.
