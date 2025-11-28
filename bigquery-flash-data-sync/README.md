# BigQuery Flash Data Sync

A Go-based CLI that streams rows from multiple SQL databases (MySQL / PostgreSQL) into Google BigQuery with automatic schema inference, configurable table batching, and structured logging.

## ✅ Highlights
- Dynamic configuration for any number of databases + tables through environment variables.
- Schema inference and type mapping that adapt to MySQL/PostgreSQL sources before loading into BigQuery.
- Concurrent table jobs powered by `errgroup` + BigQuery JSON load jobs with optional table creation/truncation.
- Safety features: dry-run mode, max row parse failure threshold, configurable batching, and database-specific TLS/timeouts.

## 🛠 Requirements
- Go 1.21+
- Google Cloud SDK (BigQuery API enabled and authenticated)
- Source databases reachable (MySQL 5.7+/PostgreSQL 12+) with read permissions
- Service account with `bigquery.dataEditor` and `bigquery.jobUser` roles

## 🚀 Quick start
```bash
# 1. Enter the repo
cd bigquery-flash-data-sync

# 2. Install dependencies
go mod download

# 3. Bootstrap your configuration
cp .env.example .env
# edit .env (see Configuration below)

# 4. Run locally
DRY_RUN=true go run ./cmd/datasync

# 5. Build for production
go build -ldflags "-X main.Version=1.0.0" -o bin/datasync ./cmd/datasync
./bin/datasync
```

## ⚙️ Configuration overview
All runtime settings are loaded from environment variables (see `.env.example`). Variables fall into several categories:

### Global BigQuery & runtime settings
| Variable | Description | Default |
| --- | --- | --- |
| `GCP_PROJECT_ID` | Target Google Cloud project | _required_ |
| `BQ_DATASET_ID` | BigQuery dataset where tables are created | _required_ |
| `SYNC_TIMEOUT` | Pipeline timeout (Go duration) | `10m` |
| `DRY_RUN` | Skip BigQuery writes while exercising extraction | `false` |
| `AUTO_CREATE_TABLES` | Create BigQuery tables when missing | `true` |
| `TRUNCATE_ON_SYNC` | Replace table contents on first load | `false` |
| `MAX_ROW_PARSE_FAILURES` | Allowed row parse errors per table (`-1` != unlimited) | `100` |
| `DATE_FORMAT` | Layout for timestamp parsing (`time` package format) | `2006-01-02T15:04:05Z07:00` |
| `DEFAULT_BATCH_SIZE` | Rows buffered before each load job | `1000` |

### Global database defaults (used when per-db override missing)
| Variable | Description | Default |
| --- | --- | --- |
| `DB_HOST` | Default host | `localhost` |
| `DB_PORT` | Default port | `3306` |
| `DB_TYPE` | Default driver (`mysql` or `postgres`) | `mysql` |
| `DB_MAX_OPEN_CONNECTIONS` | Connection pool size | `15` |
| `DB_MAX_IDLE_CONNECTIONS` | Idle pool size | `5` |
| `DB_CONN_MAX_LIFETIME` | Lifetime for pooled connections | `1m` |

### Per-database configuration
1. List identifiers in `SYNC_DATABASES` (e.g., `finance,salesforce`).
2. Prefix all other variables with the uppercase identifier, e.g., `FINANCE_DB_HOST`, `FINANCE_TABLES`.
3. Required from each database: `{ID}_DB_NAME`, `{ID}_DB_USER`, `{ID}_TABLES`.
4. Optional overrides include `{ID}_DB_TYPE`, `{ID}_HOST`, `{ID}_PORT`, `{ID}_ENABLED`.

### Table-specific overrides (optional)
Use `{DATABASE}_{TABLE}_SETTING`, e.g.,
```bash
FINANCE_INVOICES_BATCH_SIZE=5000
FINANCE_INVOICES_PRIMARY_KEY=invoice_id
FINANCE_INVOICES_COLUMNS=invoice_id,customer_id,net_amount,status
FINANCE_INVOICES_TIMESTAMP_COLUMN=updated_at
FINANCE_INVOICES_TARGET_TABLE=finance_invoices
```

Additional env vars recognized during table loading:
`{DB}_DB_CONN_TIMEOUT`, `{DB}_DB_READ_TIMEOUT`, `{DB}_DB_WRITE_TIMEOUT` (default 30s/60s/60s) ensure drivers close hanging sockets.

## ▶️ Running the sync
- `go run ./cmd/datasync` for rapid iteration (respects `.env`).
- Build once with `go build -o bin/datasync` for deployments; `Version`, `BuildTime`, and `GitCommit` can be injected with `-ldflags`.
- Increase visibility: set `LOG_LEVEL=debug` and `LOG_ENV=prod` for structured JSON logs.
- Use `DRY_RUN=true` to validate extraction without touching BigQuery.

## 🧠 Architecture
- `cmd/datasync/main.go`: bootstraps logging (Zap), loads config, and orchestrates the pipeline.
- `internal/config`: environment parsing, connection string construction, and validation with helpers for durations/booleans.
- `internal/logger`: centralized Zap logger with `dev` vs `prod` formats.
- `internal/model`: domain models including `Config`, `DatabaseConfig`, `TableConfig`, `SyncResult`, and helpers for parsing/inference.
- `internal/pipeline`: concurrent ETL with schema inference, BigQuery loader, retry-friendly buffers, and sync summaries.

### How it works
1. Load env vars, build database/table metadata, and summarize enabled tables.
2. Start a `bigquery.Client` and spin up `errgroup` workers per table (parallel per database).
3. For each table: open a DB connection, infer schema from `LIMIT 1`, buffer rows in batches, and launch a JSON load job.
4. Optional table creation/truncation happens before the first load. Dry-run short-circuits before BigQuery writes.
5. Upon completion, pipeline logs per-table results plus success/failure counts.

## 🪛 Troubleshooting
- Connectivity: use `mysql`/`psql` commands with the same credentials and host/port.
- BigQuery access: `bq ls --project_id=$GCP_PROJECT_ID $BQ_DATASET_ID`.
- Row parsing errors: increase `MAX_ROW_PARSE_FAILURES` or narrow `{TABLE}_COLUMNS` to avoid malformed data.
- Timeout adjustments: tune `SYNC_TIMEOUT`, `{DB}_DB_CONN_TIMEOUT`, `{DB}_DB_READ_TIMEOUT`, and `{DB}_DB_WRITE_TIMEOUT`.
- Logs: set `LOG_LEVEL=debug` for SQL statements, BigQuery job IDs, and error details.

## 🗂 Project layout
```
bigquery-flash-data-sync/
├── .choreo/               # Deployment metadata for WSO2 Choreo
├── .env.example          # Full set of supported environment variables
├── cmd/datasync/main.go  # Application entry point
├── go.mod                # Module definition
├── go.sum                # Dependency checksums
└── internal/
    ├── config/           # Env parsing + connection helpers
    ├── logger/           # Zap wiring
    ├── model/            # Config, schema, and result models
    └── pipeline/         # ETL orchestration and BigQuery uploads
```

## 🧾 License
Copyright 2025 WSO2 LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.# BigQuery Flash Data Sync

A Go application that synchronizes SQL databases (MySQL, PostgreSQL) to Google Cloud BigQuery with automatic schema inference, concurrent processing, and dynamic multi-database configuration.

## 📋 Quick Start

### Prerequisites

- Go 1.21+
- Google Cloud SDK with BigQuery API enabled
- MySQL 5.7+ or PostgreSQL 12+ with read access
- Service account with `bigquery.dataEditor` and `bigquery.jobUser` roles

### Installation

```bash
# Clone and navigate
cd bigquery-flash-data-sync

# Install dependencies
go mod download

# Set up authentication
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Build
go build -o bin/datasync cmd/datasync/main.go
```

### Run

```bash
# Development
go run ./cmd/datasync

# Production (using built binary)
./bin/datasync
```

## ⚙️ Configuration

Copy `.env.example` to `.env` and configure your databases dynamically.

### Minimal Configuration

```bash
# Google Cloud / BigQuery
GCP_PROJECT_ID=my-gcp-project-123
BQ_DATASET_ID=analytics_data

# Databases to sync (comma-separated identifiers)
SYNC_DATABASES=finance,salesforce

# Finance Database
FINANCE_ENABLED=true
FINANCE_DB_TYPE=mysql
FINANCE_DB_HOST=finance-db.example.com
FINANCE_DB_PORT=3306
FINANCE_DB_NAME=finance_prod
FINANCE_DB_USER=reader
FINANCE_DB_PASSWORD=secret
FINANCE_TABLES=invoices,payments,accounts

# Salesforce Database
SALESFORCE_ENABLED=true
SALESFORCE_DB_TYPE=mysql
SALESFORCE_DB_HOST=salesforce-db.example.com
SALESFORCE_DB_PORT=3306
SALESFORCE_DB_NAME=salesforce_mirror
SALESFORCE_DB_USER=reader
SALESFORCE_DB_PASSWORD=secret
SALESFORCE_TABLES=opportunities,contacts
```

### Configuration Reference

| Variable                  | Description                                   | Default      |
| ------------------------- | --------------------------------------------- | ------------ |
| `GCP_PROJECT_ID`          | Google Cloud Project ID                       | _required_   |
| `BQ_DATASET_ID`           | BigQuery dataset ID                           | _required_   |
| `SYNC_DATABASES`          | Comma-separated database identifiers          | _required_   |
| `DB_TYPE`                 | Default database type (`mysql` or `postgres`) | `mysql`      |
| `DB_HOST`                 | Default database host                         | `localhost`  |
| `DB_PORT`                 | Default database port                         | `3306`       |
| `DB_MAX_OPEN_CONNECTIONS` | Max concurrent connections                    | `15`         |
| `DB_MAX_IDLE_CONNECTIONS` | Max idle connections                          | `5`          |
| `DB_CONN_MAX_LIFETIME`    | Connection lifetime                           | `1m`         |
| `SYNC_TIMEOUT`            | Total sync timeout                            | `10m`        |
| `DATE_FORMAT`             | Timestamp format                              | `2006-01-02` |
| `DEFAULT_BATCH_SIZE`      | Rows per batch                                | `1000`       |
| `DRY_RUN`                 | Test without writing to BigQuery              | `false`      |
| `AUTO_CREATE_TABLES`      | Auto-create BigQuery tables                   | `true`       |
| `TRUNCATE_ON_SYNC`        | Delete data before sync                       | `false`      |
| `LOG_ENV`                 | Logging format (`dev` or `prod`)              | `dev`        |
| `LOG_LEVEL`               | Log level                                     | `info`       |

### Per-Database Configuration

For each database in `SYNC_DATABASES`, use the pattern `{DATABASE_ID}_SETTING`:

```bash
# Example: FINANCE database
FINANCE_ENABLED=true
FINANCE_DB_TYPE=mysql
FINANCE_DB_HOST=db.example.com
FINANCE_DB_PORT=3306
FINANCE_DB_NAME=finance_prod
FINANCE_DB_USER=reader
FINANCE_DB_PASSWORD=secret
FINANCE_TABLES=table1,table2,table3
```

### Per-Table Configuration (Optional)

For fine-grained control, use the pattern `{DATABASE_ID}_{TABLE_NAME}_SETTING`:

```bash
FINANCE_INVOICES_ENABLED=true
FINANCE_INVOICES_TARGET_TABLE=finance_invoices
FINANCE_INVOICES_PRIMARY_KEY=invoice_id
FINANCE_INVOICES_TIMESTAMP_COLUMN=updated_at
FINANCE_INVOICES_COLUMNS=id,amount,status
FINANCE_INVOICES_BATCH_SIZE=5000
```

See [`.env.example`](.env.example) for complete documentation.

## 🏗 How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  MySQL/Postgres │────▶│  Schema Inference │────▶│    BigQuery     │
│   Databases     │     │  & Data Extract   │     │    Dataset      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

1. **Configuration Loading**: Reads environment variables and builds database/table configs
2. **Schema Inference**: Automatically detects source schemas and maps to BigQuery types
3. **Concurrent Processing**: Parallel extraction and loading of multiple tables
4. **Data Sanitization**: Handles special characters, NULLs, and invalid UTF-8
5. **BigQuery Loading**: Creates/updates tables and loads data with `WRITE_TRUNCATE`

### Supported Type Mappings

| MySQL Type             | PostgreSQL Type | BigQuery Type |
| ---------------------- | --------------- | ------------- |
| VARCHAR, TEXT          | VARCHAR, TEXT   | STRING        |
| INT, BIGINT            | INTEGER, BIGINT | INTEGER       |
| FLOAT, DOUBLE, DECIMAL | FLOAT, NUMERIC  | FLOAT         |
| DATE                   | DATE            | DATE          |
| TIME                   | TIME            | TIME          |
| DATETIME, TIMESTAMP    | TIMESTAMP       | TIMESTAMP     |
| BOOLEAN                | BOOLEAN         | BOOLEAN       |
| BLOB, BINARY           | BYTEA           | BYTES         |
| JSON                   | JSON, JSONB     | JSON          |

## 📁 Project Structure

```
bigquery-flash-data-sync/
├── README.md                    # This file
├── .env.example                 # Configuration template
├── go.mod                       # Go module dependencies
├── go.sum                       # Dependency checksums
├── assets/
│   └── schemas/                 # Schema documentation
├── cmd/
│   └── datasync/
│       └── main.go              # Application entry point
└── internal/
    ├── config/
    │   └── config.go            # Environment variable loading
    ├── logger/
    │   └── logger.go            # Structured logging (zap)
    ├── model/
    │   ├── models.go            # Data structures & types
    │   └── parser.go            # Row parsing & type conversion
    └── pipeline/
        ├── bqsetup.go           # Schema inference & table management
        └── job.go               # ETL job orchestration
```

## 🔧 Adding New Databases

Simply update your `.env` file:

```bash
# 1. Add to SYNC_DATABASES
SYNC_DATABASES=finance,salesforce,inventory

# 2. Configure the new database
INVENTORY_ENABLED=true
INVENTORY_DB_TYPE=postgres
INVENTORY_DB_HOST=inventory-db.example.com
INVENTORY_DB_PORT=5432
INVENTORY_DB_NAME=inventory_prod
INVENTORY_DB_USER=reader
INVENTORY_DB_PASSWORD=secret
INVENTORY_TABLES=products,stock_levels,warehouses
```

No code changes required! Schema detection is automatic.

## 🐛 Troubleshooting

### Connection Issues

```bash
# Verify MySQL connectivity
mysql -h $DB_HOST -P $DB_PORT -u $USER -p -e "SHOW TABLES"

# Verify PostgreSQL connectivity
psql -h $DB_HOST -p $DB_PORT -U $USER -d $DB_NAME -c "\dt"

# Check BigQuery access
bq ls --project_id=$GCP_PROJECT_ID $BQ_DATASET_ID
```

### Enable Debug Logging

```bash
LOG_LEVEL=debug go run ./cmd/datasync
```

### Common Errors

| Error                                  | Solution                                          |
| -------------------------------------- | ------------------------------------------------- |
| `Table 'database.table' doesn't exist` | Check table names in `{DB}_TABLES` variable       |
| `dial tcp: i/o timeout`                | Verify `DB_HOST` and `DB_PORT`, check firewall    |
| `Access denied`                        | Verify credentials and user permissions           |
| `Permission denied` (BigQuery)         | Add `bigquery.dataEditor` role to service account |
| `invalid character`                    | Enable debug mode, check for invalid UTF-8 data   |
| `context deadline exceeded`            | Increase `SYNC_TIMEOUT` value                     |

### Test Mode

Run without writing to BigQuery:

```bash
DRY_RUN=true go run ./cmd/datasync
```

## 📊 Performance

| Rows | Columns | Tables | Sync Time | Memory |
| ---- | ------- | ------ | --------- | ------ |
| 1K   | 10      | 5      | ~3s       | ~50MB  |
| 50K  | 25      | 10     | ~20s      | ~200MB |
| 500K | 50      | 15     | ~120s     | ~800MB |

### Optimization Tips

- Increase `DB_MAX_OPEN_CONNECTIONS` for more parallelism
- Adjust `DEFAULT_BATCH_SIZE` based on row size
- Set appropriate `SYNC_TIMEOUT` for large datasets
- Use `{TABLE}_COLUMNS` to sync only needed columns

## 🔒 Security Best Practices

- Never commit `.env` to version control (add to `.gitignore`)
- Use read-only database users with minimal permissions
- Store production credentials in a secret manager (e.g., Google Secret Manager)
- Enable TLS/SSL for all database connections
- Rotate credentials regularly
- Use service accounts with least-privilege IAM roles

## 📝 License

Copyright 2025 WSO2 LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

**Maintained by**: WSO2 Internal Apps Team
