

Implement the changes to LSM suggested in the [paper](http://dl.acm.org/citation.cfm?id=3101295):
**Verifying the reliability of operating system-level information flow control systems in linux**, Georget et al., ACM/IEEE Workshop on Formal Methods in Software Engineering (FormliSE'17) 2017

The original patches can be found on the authors [website](http://kayrebt.gforge.inria.fr/pathexaminer.html). Further changes have been made to those patches.

To generate the patches:
```
git clone https://github.com/camflow/information-flow-patch
cd ./information-flow-patch
make prepare
make patch
```

The generated patch can be found in /output.
