# ADR: Qdrant MCP for Agentic Retrieval

| Field | Value |
|---|---|
| status | Accepted |
| date | 2026-09-28 |

## Context

The retrieval agent uses Qdrant for semantic vector search and Neo4j for
relationships between Kubernetes resources.

The existing implementation uses a custom Qdrant MCP with Nomic embeddings.
The alternative uses the official `mcp-server-qdrant` with
`sentence-transformers/all-MiniLM-L6-v2`.

The goal was to compare both configurations using the same Kubernetes Agent
data and retrieval questions.

## Decision

Evaluate both Qdrant MCP implementations while keeping GPT-5 mini and Neo4j
unchanged.

| | Custom Qdrant MCP | Official Qdrant MCP |
|---|---|---|
| Collection | `abox-nomic` | `abox-minilm` |
| Embedding | Nomic | `all-MiniLM-L6-v2` |
| Vector size | 768 | 384 |
| Store tool | `vector_store` | `qdrant-store` |
| Search tool | `vector_find` | `qdrant-find` |

Separate collections are used because the embedding models have different
vector dimensions.

## Indexing

The dataset consisted of 7 Kubernetes `Agent` resources.

The same indexing prompt was used for both configurations:

> In namespace kagent, retrieve all Agent resources. Index their metadata,
> description, system prompt, model configuration, tools, and agent references.
> Create vector embeddings and graph relationships from this data. Do not index
> Secrets or controller-generated resources.

### Collection State

| Collection | Embedding | Vector size | Points observed |
|---|---|---:|---:|
| `abox-nomic` | Nomic | 768 | 7 |
| `abox-minilm` | `all-MiniLM-L6-v2` | 384 | 3 |

The custom configuration produced 7 points in `abox-nomic`.

During official-MCP indexing, the agent reported successful indexing of all
7 Agent resources, while `abox-minilm` contained 3 points.

The exact cause of this discrepancy was not established. Therefore, the point
count is treated as an observed indexing difference rather than an embedding
quality result.

## Retrieval Evaluation

Six questions were used for the initial Agentic Retrieval evaluation.

### 1. Kubernetes Operations

**Question:** Which Agent is responsible for Kubernetes operations?

- Custom + Nomic: `k8s-agent`
- Official + MiniLM: `k8s-agent`

Both configurations identified the same Kubernetes-specialized Agent.

### 2. Agent Delegation

**Question:** Which Agents delegate tasks to another Agent?

Both configurations identified the Agent delegation relationships, including
`observability-agent` → `promql-agent` and
`retrieval-agent` → `k8s-agent`.

This question mainly exercised Neo4j relationships rather than semantic vector
similarity.

### 3. Shared ModelConfig

**Question:** Which Agents use the same ModelConfig?

Both configurations produced the same grouping.

The default model configuration was shared by
`argo-rollouts-conversion-agent`, `helm-agent`, `kgateway-agent`,
`observability-agent`, and `promql-agent`.

`k8s-agent` and `retrieval-agent` used `openai-gpt-5-mini`.

This was primarily a structured relationship query resolved through Neo4j.

### 4. Similar Responsibilities

**Question:** Which two Agents have the most similar responsibilities based on
their descriptions?

- Custom + Nomic: `observability-agent`, `promql-agent`
- Official + MiniLM: `observability-agent`, `promql-agent`

Both configurations identified the same pair.

### 5. k8s-agent Tools and Relationships

**Question:** What tools and relationships are associated with `k8s-agent`?

Both configurations retrieved the tools and relationships associated with
`k8s-agent`.

This question mainly exercised Neo4j because it required explicit structured
relationships.

### 6. Kubernetes Application Diagnosis

**Question:** Which Agent is most relevant for diagnosing problems with
applications running in the Kubernetes cluster?

- Custom + Nomic: `k8s-agent`
- Official + MiniLM: `k8s-agent`

Both configurations selected the same Agent based on its Kubernetes operations
and troubleshooting responsibilities.

## Vector-Only Validation

Additional questions were asked with instructions to use only the existing
vector index and not Neo4j.

| Question | Custom + Nomic | Official + MiniLM |
|---|---|---|
| Install, upgrade, or troubleshoot an application deployed with Helm | `helm-agent` | `helm-agent` |
| Configure and troubleshoot Kubernetes gateway and traffic routing | `kgateway-agent` | `kgateway-agent` |
| Migrate a Deployment to progressive rollout with controlled traffic shifting | `argo-rollouts-conversion-agent` | `argo-rollouts-conversion-agent` |

The custom configuration used `vector_find`, while the official configuration
used `qdrant-find`.

Both configurations returned the same relevant Agent for all three comparable
vector-only questions.

The custom MCP exposed similarity scores of approximately 0.73–0.79.
Comparable verified scores were not available from the official MCP, so
absolute similarity scores were not compared.

An additional harder query combined progressive delivery, traffic routing, and
rollout-health concepts. The official configuration selected
`argo-rollouts-conversion-agent`, prioritizing the progressive-delivery intent.
This query was not used as a direct A/B result because an equivalent verified
custom-MCP run was not completed.

## Analysis

Both configurations produced equivalent answers for the comparable retrieval
questions.

Relationship-oriented questions were mainly resolved through Neo4j. The
vector-only questions provided a more direct comparison of semantic retrieval,
and both configurations selected the same Agents for Helm operations, Gateway
routing, and progressive delivery.

The main observed difference was collection state:

- Custom MCP + Nomic: **7 points**
- Official MCP + MiniLM: **3 points**

Therefore, the experiment did not show a meaningful difference in answer
quality for the tested semantic queries. It did show a difference in indexing
completeness between the two configurations.

Because the MCP implementation, embedding model, and resulting collection
contents differed, the experiment does not establish that either Nomic or
MiniLM provides better embedding quality.

## Consequences

- The official `mcp-server-qdrant` can be integrated with the retrieval agent
  using `qdrant-store` and `qdrant-find`.
- MiniLM uses 384-dimensional vectors compared with 768 for the Nomic setup.
- Nomic and MiniLM are stored in separate Qdrant collections.
- Both configurations returned the same relevant Agents for the comparable
  semantic retrieval tests.
- Custom MCP indexing resulted in 7 observed points, while official MCP
  indexing resulted in 3 observed points.
- The main observed difference was indexing completeness rather than retrieval
  answer quality.
- Agent-reported indexing success should be verified against the actual Qdrant
  collection state.
- Further investigation is required to determine the cause of the official
  MCP indexing discrepancy.