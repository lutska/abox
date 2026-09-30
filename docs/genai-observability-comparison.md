## GenAI Observability Solutions Comparison

### References

- [OpenTelemetry](https://opentelemetry.io/docs/)
- [MLflow AI Platform — GenAI](https://mlflow.org/docs/latest/genai/)
- [Phoenix — Arize AI](https://arize.com/docs/phoenix/)
- [Jaeger](https://www.jaegertracing.io/docs/)

### Architecture

```
                         Astronomy Shop
                    Chatbot + GenAI Agent
                 LangGraph / LangChain / OpenAI
                              │
                              │ OTLP
                              │
                              ▼
                ┌──────────────────────────┐
                │   OpenTelemetry Demo     │
                │   Collector              │
                │                          │
                │ • traces / spans         │
                │ • gen_ai.* attributes    │
                │ • context propagation    │
                │ • normalization          │
                └────────────┬─────────────┘
                             │
                  SAME OTEL TELEMETRY
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
       ┌────────────┐             ┌──────────────────┐
       │   Jaeger   │             │   OTEL Bridge    │
       │            │             │   Collector      │
       │ Generic    │             │                  │
       │ tracing UI │             │ routes / exports │
       └──────┬─────┘             └────────┬─────────┘
              │                            │
              │                     ┌──────┴──────┐
              │                     │             │
              ▼                     ▼             ▼
       Distributed           ┌─────────────┐ ┌─────────────┐
       span tree             │   MLflow    │ │   Phoenix   │
       gen_ai.*              │             │ │             │
       attributes            │ GenAI / ML  │ │ GenAI / LLM │
       latency               │ observability│ │ observability│
                             └──────┬──────┘ └──────┬──────┘
                                    │               │
                                    ▼               ▼
                                 Prompts         LLM spans
                                 responses       prompts
                                 models          responses
                                 tokens          tokens
                                 cost            tools
                                 evaluation      evaluation
```

### omparison table
---

| Capability | Standard OpenTelemetry | MLflow | Phoenix | Jaeger *(additional OTEL UI)* |
|---|---|---|---|---|
| **Primary purpose** | Vendor-neutral telemetry standard | GenAI/ML observability and lifecycle | LLM/agent observability and evaluation | General-purpose distributed tracing |
| **Role in our setup** | Telemetry collection and transport layer | GenAI/ML observability platform | GenAI/LLM observability platform | General-purpose distributed tracing platform |
| **Trace representation** | Spans, attributes and parent/child relationships | GenAI trace tree + timeline | Interactive LLM/agent trace | Distributed span timeline |
| **Agent workflow** | Represented as OTEL spans | Shows `astronomy_shop_agent_workflow → invoke_agent → LangGraph.workflow → execute_task → ChatLLM.chat` | Shows the same agent/LLM hierarchy | Shows the same hierarchy as generic spans |
| **LLM call** | Represented using GenAI semantic attributes | `ChatLLM.chat` shown as a model/GenAI operation | `ChatLLM.chat` recognized as an LLM operation | `ChatLLM.chat` shown as a normal trace span |
| **Prompt / response** | Stored in `gen_ai.*` attributes when instrumentation records them | Dedicated User / Assistant view | Structured input/output messages | Visible by expanding span attributes |
| **Model** | e.g. `gen_ai.request.model` | `gpt-5-mini` and response model visible | `gpt-5-mini` visible in LLM attributes | Model available through `gen_ai.*` tags |
| **Token usage** | Standard `gen_ai.usage.*` attributes | Total tokens clearly displayed | Total + prompt/completion breakdown | Token attributes can be inspected manually |
| **Example from our trace** | Same OTEL trace carries the GenAI data | **4,285 tokens**, ~**13.38 s** | **4,285 tokens** = 3,132 input + 1,153 output, ~**13.3 s** | Prompt, response and `ChatLLM.chat` visible in the trace |
| **Cost** | OTEL itself does not provide a cost-analysis UI | **$0.002542** shown for our trace | Cost displayed (`<$0.01` in our trace) | No specialized GenAI cost view |
| **Latency** | Derived from span timestamps/durations | Displayed per trace/span | Displayed per trace/span | Excellent distributed timeline |
| **Tool calls** | Can be represented as spans/attributes | Visible within GenAI trace | Detailed tool definitions/schemas visible | Visible as ordinary spans/attributes |
| **Trace search** | Depends on chosen backend | Convenient trace browsing/search | Powerful filtering; sometimes requires query expressions | Search by service, operation, tags and time |
| **Evaluation features** | Not part of OTEL itself | Judges, Review, Evaluation Runs | Evaluators and Experiments | Not an evaluation platform |
| **Datasets** | No dataset management | Yes | Yes | No |
| **GenAI-specific UX** | None by itself; defines the telemetry | Strong | Strong | Limited — primarily generic tracing |
| **Main strength for GenAI** | **Standardization and portability** | **Easy end-to-end GenAI inspection + evaluation** | **Detailed LLM/tool inspection + evaluation** | **Clear view of the underlying distributed trace** |
| **Main limitation for GenAI** | Requires a backend/UI for practical investigation | More specialized than plain telemetry | Trace discovery/filtering can be more complex | GenAI data is mostly presented as generic span attributes |



### Experiment

The same GenAI interaction was inspected through Jaeger, MLflow, and Phoenix:

> `LAB7-TRACE-004: compare the best two telescopes for viewing planets and recommend one`

The trace contained the following agent/LLM hierarchy:

```text
astronomy_shop_agent_workflow
└── invoke_agent LangGraph
    └── LangGraph.workflow
        └── execute_task model
            └── ChatLLM.chat
                └── POST
```

OpenTelemetry provides the underlying spans and gen_ai.* semantic attributes. It is therefore the standardization and transport layer, rather than a complete GenAI observability UI.

Jaeger proves that the standard OTEL data already contains useful GenAI information. We could expand ChatLLM.chat and inspect the prompt, response, attributes and latency, but these are presented as conventional trace/span data.

MLflow interprets that telemetry specifically for GenAI. In our trace it made the model, prompt/response, 4,285 tokens, 13.38 s latency, and $0.002542 cost easy to inspect.

Phoenix also interprets the trace as GenAI telemetry and provided particularly detailed LLM information. For the same interaction we saw 4,285 tokens = 3,132 input + 1,153 output, approximately 13.3 s latency, messages, model information, finish reason, and available tool schemas.


### Key observations
```
OpenTelemetry → standardizes and transports the telemetry
Jaeger        → shows the telemetry as conventional distributed traces
MLflow        → interprets it for GenAI + ML lifecycle/evaluation
Phoenix       → interprets it for detailed LLM/agent analysis + evaluation
```


### Conclusion

The experiment shows that OpenTelemetry, MLflow, and Phoenix play different roles in GenAI observability.

**OpenTelemetry** provides the vendor-neutral foundation for collecting and transporting traces, spans, and standardized `gen_ai.*` attributes. This allows the same application telemetry to be sent to different observability platforms without changing the application instrumentation.

**MLflow** and **Phoenix** build on this telemetry with GenAI-specific views and features. MLflow provides clear visualization of LLM/agent traces, prompts and responses, models, token usage, cost, and evaluation workflows. Phoenix provides detailed LLM and agent inspection, including messages, token breakdowns, tool definitions, and evaluation capabilities.

**Jaeger** was used as an additional general-purpose tracing platform. It confirmed that GenAI information such as prompts, responses, agent hierarchy, latency, and `gen_ai.*` attributes is already present in the OpenTelemetry traces, but is displayed mainly as standard spans and attributes rather than through a GenAI-specific interface.

Overall, **OpenTelemetry provides standardization and portability**, **MLflow and Phoenix provide higher-level GenAI observability and evaluation**, while **Jaeger provides a clear view of the underlying distributed traces**.