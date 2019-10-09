# DAOR - Parameter-free Embedding Framework for Large Graphs (Networks) 

`\authors` (c) Artem Lutov <artem@exascale.info>  
`\license` AGPL 3.0, optional commercial support and relicensing is provided by the request  
`\organizations` [eXascale Infolab](http://exascale.info/), [Lumais](http://www.lumais.com/)  
`\keywords` parameter-free graph embedding, unsupervised
learning of network representation, automatic feature extraction,
interpretable compact embeddings, scalable graph embedding

The paper:
```
@inproceedings{Daor19,
	author={Artem Lutov and Dingqi Yang and Philippe Cudr{\'e}-Mauroux},
	title={Bridging the Gap between Community and Node Representations: Graph Embedding via Community Detection},
	year={2019},
	keywords={parameter-free graph embedding, unsupervised
learning of network representation, automatic feature extraction,
interpretable compact embeddings, scalable graph embedding},
}
```

The source code is being prepared for the publication and cross-platform deployment, and will be fully uploaded soon...  
Meanwhile, please *write me to get the sources*.
The [DAOR binaries](https://github.com/eXascaleInfolab/clubmark/tree/master/algorithms/daoc) built on Linux Ubuntu 16.04+ x64 can be found in the [GraphEmbEval](https://github.com/eXascaleInfolab/GraphEmbEval) framework for the graph embedding algorithms evaluation.


## Related Projects

- [GraphEmbEval](https://github.com/eXascaleInfolab/GraphEmbEval) - Graph (Network) Embeddings Evaluation Framework via classification, which also provides gram martix construction for links prediction.
- [DAOC](https://github.com/eXascaleInfolab/daoc) - Deterministic and Agglomerative Overlapping Clustering algorithm for the stable clustering of large networks (totally redesigned former [HiReCS](https://github.com/eXascaleInfolab/hirecs) High Resolution Hierarchical Clustering with Stable State).
- [Clubmark](https://github.com/eXascaleInfolab/clubmark) - a parallel isolation framework for benchmarking and profiling clustering (community detection) algorithms considering overlaps (covers), includes a dozen of clustering algorithms for large networks.
- [PyExPool](https://github.com/eXascaleInfolab/PyExPool) - multiprocess execution pool and load balancer, which provides [external] applications scheduling for the in-RAM execution on NUMA architecture with capabilities of the affinity control, CPU cache vs parallelization maximization, memory consumption and execution time constrains specification for the whole execution pool and per each executor process (called worker, executes a job).
- [NodeSketch](https://github.com/eXascaleInfolab/NodeSketch) - Highly-Efficient Graph Embeddings via Recursive Sketching 
- [HARP](https://github.com/eXascaleInfolab/HARP) - Hierarchical Representation Learning for Networks
- [NetHash](https://github.com/eXascaleInfolab/NetHash) - Efficient Attributed Network Embedding via Recursive Randomized Hashing
- [Deepwalk](https://github.com/eXascaleInfolab/deepwalk) - Online Deep Learning of Social Representations on Graphs

**Note:** Please, [star this project](https://github.com/eXascaleInfolab/daor) if you use it.
