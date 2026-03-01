# 200 - Core Architecture

This section covers Envoy's internal architecture: its threading model, the listener → filter chain → cluster pipeline, and the concepts of upstream and downstream.

## Contents

| File | Description |
|---|---|
| [100-threading-model.md](100-threading-model.md) | Event-driven, non-blocking I/O with worker threads |
| [200-listeners-filters-clusters.md](200-listeners-filters-clusters.md) | The three core building blocks of Envoy config |
| [300-filter-chains.md](300-filter-chains.md) | How filters are composed into processing pipelines |
| [400-upstream-downstream.md](400-upstream-downstream.md) | Envoy's traffic directionality concepts |
