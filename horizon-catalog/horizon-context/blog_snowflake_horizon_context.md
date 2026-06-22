# Snowflake Horizon Context: The Governed Context Layer for AI, BI and Apps

## The Problem: Same Data, Different Answers

Your head of sales sees $14.2 million in Q3 revenue. Your CFO sees $12.8 million. Both asked an AI agent the same question this morning. Same data. Why the discrepancy?

This happens when business logic is scattered across separate tools: a metric defined inside a BI model only one team owns, a calculation buried in a dashboard, a set of instructions manually hardcoded into an LLM prompt. The result is not just metric drift — it is a trust gap that makes it hard to move AI projects forward with confidence.

Snowflake Horizon Context solves this by providing a **connected, governed semantic foundation with active context** for AI and BI.

---

## What is Horizon Context?

Announced at Snowflake Summit 2026, **Horizon Context** is a new capability within [Snowflake Horizon Catalog](https://www.snowflake.com/en/product/features/horizon/) that transforms raw metadata into governed business meaning. It builds on Horizon Catalog's metadata foundation by:

- **Collecting** context from across your data estate (inside and outside Snowflake)
- **Enriching** it with business definitions, relationships and quality signals
- **Activating** it so AI agents, BI tools and applications can automatically discover and apply trusted logic

The key differentiator: because Horizon Context is native to the Snowflake engine, governance is enforced at the *meaning* level, not just the table level. Role-based access control and masking policies follow the context — every tool, every query, every AI response.

---

## Architecture: Collect, Enrich, Activate

### 1. Collect: Build the Complete Picture

AI needs context from your entire data estate, not just what lives in Snowflake. Horizon Context extracts metadata from external systems and collects it in Horizon Catalog.

| Capability | Description | Status |
|---|---|---|
| **Metadata Connectors** | Connect to PostgreSQL, SQL Server, Tableau, Power BI, dbt and more. Collect schemas, query logs, dashboard definitions. | Private Preview |
| **OpenLineage API** | Configure OpenLineage producers (Apache Airflow, dbt, custom scripts) to send lineage events to Horizon Catalog. | Public Preview |
| **Open Semantic Interchange (OSI)** | An open standard for exchanging semantic metadata between disparate systems. 54+ participating vendors. | Specification Published |

### 2. Enrich: Turn Raw Metadata into Business Meaning

Raw context needs enrichment to create higher levels of meaning. Horizon Context automates much of this while keeping humans in the loop.

| Capability | Description |
|---|---|
| **Column-level lineage** | Mines lineage from Snowflake and external query logs, BI systems and OpenLineage feeds, then stitches it into a complete graph. |
| **Popularity signals** | Uses query and access logs to calculate which data assets are most used — a signal for authoritativeness when dozens of similar-looking assets exist. |
| **AI-generated documentation** | Uses AI to generate table and column descriptions from metadata and (optionally) sample data. |
| **Semantic Views** | Define business logic (metrics, dimensions, facts, relationships) once. Enhanced at Summit 2026 with LOD calculations, composable definitions and automatic query rewrite. |
| **Semantic Studio** | A full AI-assisted IDE in Workspaces with CoCo integration and Git-based versioning for building and testing semantic views. |
| **Semantic View Autopilot** | Ingests existing SQL, Tableau workbooks (.twb/.twbx) or Power BI files (.pbit/.pbix) and generates semantic views automatically. |

### 3. Activate: Make Context Work Automatically

Context only matters if it gets used. Horizon Context makes your definitions discoverable, accessible and automatically activated.

| Capability | Description |
|---|---|
| **Context Search (Universal Search)** | Hybrid keyword + semantic search across your entire data estate. Uses popularity for ranking and access control for filtering. |
| **Automatic semantic view discovery** | CoCo automatically searches for and queries relevant semantic views when asked a data question. Falls back to tables if none exist. |
| **BI interoperability** | Query governed definitions natively from Power BI, Tableau, Excel, Google Sheets, Looker, ThoughtSpot, Sigma, Hex and Omni. |
| **MCP for external agents** | Expose semantic views via Model Context Protocol (MCP), governed by Horizon Catalog. Connect from Claude, Cursor, or any agent framework. |

---

## Why This Matters for the Agentic Era

Autonomous agents cannot reason about your business if your data carries no embedded meaning:

- **Without context**, an agent guesses.
- **With context**, an agent acts.
- **With governed context**, an agent can be trusted.

A context layer bolted on top of a governance engine must reconcile two systems every time a query runs. When definitions drift, the agent follows the wrong one. Horizon Context is different because semantics live *inside* the governance engine and are enforced at query time — not copied or cached.

---

## Ecosystem Partners

Horizon Context integrates with the tools enterprises already use:

| Partner | Integration |
|---|---|
| **Tableau** | Semantic view definitions reflected in Tableau data models for consistent metric aggregation |
| **Power BI** | Native support for querying Snowflake semantic views (private preview) |
| **Looker (Google Cloud)** | Universal semantic layer extended to support in-database models with Snowflake Semantic Views |
| **ThoughtSpot** | Native support for querying semantic views enriched with AI-native context |
| **Sigma Computing** | Queries semantic views in real time; governed definitions reflected in every spreadsheet and dashboard |
| **Hex** | Trusted, governed metrics available in notebooks, SQL and data apps |
| **Omni** | Governed definitions surfaced in AI-driven chat, spreadsheets and dashboards |
| **Alation** | Governed semantic definitions connected to enterprise data catalogs |
| **Collibra** | Bidirectional trusted metadata flow for a single view of enterprise context |
| **AtScale** | Business definitions governed once and used everywhere analysts and AI work |

---

## Implementing Horizon Context: A Practical Example

The demo pipeline in this repository demonstrates the Horizon Context pattern end-to-end:

```
PostgreSQL (pg_lake)
    │
    ├── customers_iceberg
    ├── products_iceberg
    ├── orders_iceberg
    └── order_items_iceberg
            │
            ▼  [Collect: OpenLineage API registers upstream lineage]
    ┌───────────────────────────────────────────────────┐
    │  Snowflake Horizon Catalog                        │
    │                                                   │
    │  RAW Layer (Iceberg Tables via Catalog Integration)│
    │       │                                           │
    │       ▼                                           │
    │  TRANSFORM Layer (Dynamic Tables)                 │
    │       │                                           │
    │       ▼  [Enrich: Semantic View with metrics,     │
    │  ANALYTICS Layer (View)    dimensions, synonyms]  │
    │       │                                           │
    │       ▼                                           │
    │  Semantic View + Cortex Agent                     │
    │       │  [Activate: Agent auto-discovers and      │
    │       │   queries governed definitions]           │
    │       ▼                                           │
    │  Power BI Report / Streamlit Dashboard            │
    │       [Activate: downstream lineage registered]   │
    └───────────────────────────────────────────────────┘
```

### How Each Step Maps to Horizon Context

| Step | File | Horizon Context Pillar |
|------|------|------------------------|
| Postgres Iceberg tables | `setup/02_pipeline_postgres.sql` | Source data (external database) |
| Catalog integration | `setup/01_test_presetup.sql` | **Collect** - Connect external database |
| Pipeline (RAW/TRANSFORM/ANALYTICS) | `setup/03_pipeline_snowflake.sql` | Data engineering foundation |
| Semantic View + Agent | `setup/04_semantic_view_and_agent.sql` | **Enrich** - Business definitions, metrics, synonyms, AI instructions |
| External lineage (OpenLineage API) | `setup/05_register_lineage.sh` | **Collect** - Register upstream/downstream lineage |
| Streamlit Dashboard | `setup/06_streamlit_app.py` | **Activate** - Governed context surfaced in an app |

### What We Built

**Collect** -- We connected a Snowflake Postgres instance (`PG_SNOWFLAKE_PROD`) running pg_lake with managed Iceberg tables. A catalog integration (`CATALOG_SOURCE = SNOWFLAKE_POSTGRES`) exposes those Iceberg tables directly in Snowflake without data movement. We then used the OpenLineage REST API to register external lineage events so the Snowsight lineage graph shows:

- **Upstream:** PostgreSQL tables (with the Postgres icon) feeding into `HRZN_DB.RAW.*`
- **Downstream:** `V_ORDER_ANALYTICS` feeding a Power BI report (with the Power BI icon)

Key discovery: Use the `postgresql://` namespace (not `postgres://`) with `"sourceType": {"sourceType": "POSTGRESQL"}` facets to render the Postgres icon. Use `"datasetType": {"datasetType": "REPORT"}` facets for downstream BI output nodes.

**Enrich** -- We created a semantic view (`HRZN_DB.ANALYTICS.ORDER_ANALYTICS_SEMANTIC_VIEW`) with:

- 10 facts (quantity, prices, margins, customer lifetime metrics)
- 11 dimensions (dates, status, customer/product attributes with synonyms)
- 6 metrics (total revenue, gross margin, units sold, order count, AOV, margin %)
- AI instructions (`AI_SQL_GENERATION` for safe division, rounding; `AI_QUESTION_CATEGORIZATION` to reject out-of-scope questions)

This is the governed business logic layer -- define "revenue" and "margin" once, and every downstream tool (agent, dashboard, BI tool) gets the same answer.

**Activate** -- We created a Cortex Agent (`ORDER_ANALYTICS_AGENT`) with JSON specification that uses `cortex_analyst_text_to_sql` to automatically query the semantic view. The agent does not need to know table schemas or SQL -- it discovers governed definitions from the semantic view and generates correct queries. We also deployed a Streamlit-in-Snowflake dashboard that queries the same view, demonstrating governed context activated in two different consumption patterns simultaneously.

### The Resulting Lineage Graph

The complete lineage visible in Snowsight:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐     ┌───────────────┐
│ PostgreSQL  │     │  HRZN_DB    │     │  HRZN_DB        │     │  HRZN_DB      │
│ (pg_lake)   │────>│  RAW        │────>│  TRANSFORM      │────>│  ANALYTICS    │
│             │     │             │     │                 │     │               │
│ customers   │     │ CUSTOMERS_  │     │ DT_ORDER_       │     │ V_ORDER_      │──┐
│ products    │     │ ICEBERG     │     │ DETAILS         │     │ ANALYTICS     │  │
│ orders      │     │ PRODUCTS_   │     │                 │     │               │  │
│ order_items │     │ ICEBERG     │     │ DT_CUSTOMER_    │     └───────────────┘  │
└─────────────┘     │ ORDERS_     │     │ SUMMARY         │                        │
                    │ ICEBERG     │     └─────────────────┘         ┌──────────────┼──────────────┐
                    │ ORDER_ITEMS │                                  │              │              │
                    │ _ICEBERG    │                                  ▼              ▼              ▼
                    └─────────────┘                            Power BI      Streamlit      Cortex Agent
                                                              Report        Dashboard      (Snowflake
                                                                                           Intelligence)
```

---

## Key Takeaways

1. **Define once, use everywhere.** Semantic Views are the governed foundation — metrics, dimensions and business logic defined in one place and consumed by every tool.

2. **Context must be active, not passive.** It is not enough to store metadata. Horizon Context activates it so agents and tools discover and apply definitions automatically.

3. **Governance at the meaning level.** Unlike bolt-on semantic layers, Horizon Context enforces RBAC and masking at the semantic layer — a definition restricted for finance stays restricted in Power BI, Salesforce and any agent.

4. **Open ecosystem.** OpenLineage for lineage ingestion, OSI for semantic interchange, MCP for agent access, and native connectors for BI tools.

5. **Built for agents.** As AI agents move from experimentation to production, they need governed context to produce trusted answers. Horizon Context is designed for this agentic era.

---

## References

### Snowflake Official

- [Snowflake Blog: Horizon Context - The Governed Context Layer for AI, BI and Apps](https://www.snowflake.com/en/blog/horizon-context-governed-context/) (Jun 2, 2026)
- [Snowflake Product Page: Horizon Context](https://www.snowflake.com/en/product/features/horizon-context/)
- [Snowflake Horizon Catalog: Data Governance & Discovery](https://www.snowflake.com/en/product/features/horizon/)
- [Snowflake Press Release: Advances Trusted AI with Horizon Catalog](https://www.snowflake.com/en/news/press-releases/snowflake-advances-trusted-ai-with-snowflake-horizon-catalog-centralizing-governance-context-and-security-across-the-enterprise/)
- [Snowflake Press Release: Enterprise Data AI-Ready with Snowflake Postgres](https://www.snowflake.com/en/news/press-releases/snowflake-makes-enterprise-data-ai-ready-with-snowflake-postgres-and-advanced-innovations-for-open-data-interoperability/) (Feb 3, 2026)
- [Open Semantic Interchange Specification](https://www.snowflake.com/en/blog/open-semantic-interchanges-specs-finalized/)

### Snowflake Documentation

- [Semantic Views Overview](https://docs.snowflake.com/en/user-guide/views-semantic/overview)
- [CREATE SEMANTIC VIEW DDL](https://docs.snowflake.com/en/sql-reference/sql/create-semantic-view)
- [External Lineage (OpenLineage API)](https://docs.snowflake.com/en/user-guide/external-lineage)
- [Snowflake Postgres: pg_lake](https://docs.snowflake.com/en/user-guide/snowflake-postgres/postgres-pg_lake)
- [Data Lineage in Snowsight](https://docs.snowflake.com/en/user-guide/ui-snowsight-lineage)

### Third-Party Analysis

- [Snowflake Summit 2026: Summary of New Features (Medium / Snowflake Builders Blog)](https://medium.com/snowflake/snowflake-summit-2026-summary-of-new-features-09f3d5ffeefe)
- [Atlan: Snowflake Summit 2026 Announcements and What They Mean](https://atlan.com/know/snowflake/summit-2026-announcements/)
- [Atlan: Context Layer for Snowflake - Native + Enterprise Guide 2026](https://atlan.com/know/context-layer-for-snowflake/)
- [Atlan: Snowflake Semantic Views - A Complete 2026 Enterprise Guide](https://atlan.com/know/snowflake/snowflake-semantic-views/)
- [Constellation Research: Snowflake Summit 2026 - Redrawing the Boundary Between Data, Context, and Action](https://www.constellationr.com/research/blog/snowflake-summit-2026-redrawing-boundary-between-data-context-and-action)
- [DataHub: Context Layer for Snowflake](https://datahub.com/blog/context-layer-for-snowflake/)
