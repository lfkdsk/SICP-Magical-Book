---
title: 0x07：SICP 的魔法 - 元语言抽象
date: 2019-03-18 10:54:16
tags: SICP
---

从这一篇文章开始就进入了 SICP 第四章的内容了，在前三章的内容之中我们接触了 `数据抽象`，`过程抽象`，`模块化` 三个，第四章的内容主要就是实现了一个元循环解释器 (meta-circular) 并对其进行不断地改造引申出别的问题。从篇幅内容来看这一章的主要内容反倒是对当时初读的我最为简单的，因为在学过编译原理的相关课程之后，笔者已经尝试使用了自举的方式实现了一些基于 JVM 的编程语言(这里也建议大家在学习理论的同时也要加强知识的运用，否则没有实际的使用过很多知识就不是那么立体)。本章我们对这个 Scheme 求值器的具体实现不会介绍的特别具体，毕竟书上已经把全部代码都贴上去了，这里更想关注一些引申的问题。

在之前的篇幅之中我们讨论了很多和程序设计相关的内容，主要研究的三个内容是：

1. 数据抽象：如何组合程序的基本元素，构造更复杂的结构
2. 过程抽象：如何将复杂的结构抽象出高层组件，提供更高维度的组合型
3. 模块化，通过高抽象层次的组织方法，提高系统的模块性

通过这些手段已经足够我们设计大部分程序了，但是现实世界中遇到的问题可能更为复杂，或者可能类似的问题出现在同一个领域内。这时候我们可能就要在程序之中引入 **DSL**(领域内语言)了。本质上来讲我们引入 DSL 就是通过语言设计，为程序提供一种 **语言层的抽象** ，来进一步提高我们程序的模块化。

## 元语言抽象

这节之中我们会试着用 Scheme 来实现一个 Scheme 的解释器，用一种语言实现其自身的求值器，称为元循环（meta-circular）。这里我们可以复习一下 `3.2` 节之中出现的求值模型，其中的求值流程分成两步：

1. 求值组合式（非特殊形式）时
   - 先求值组合式的各子表达式
   - 把运算符子表达式的值作用于运算对象子表达式的值
2.  把复合过程应用于实参，是在一个新环境里求值过程体
   - 新环境：过程对象（里环境指针指向）的环境加一个新框架
   - 新框架里是过程的形参与对应实参的约束

这两个步骤构成了 Scheme 求值的基本循环，这两个步骤也是能相互调用和递归 (自己递归或相互递归。求值的子表达式可能要应用复合过程，过程体本身通常又是组合式)，逐步规约到：

- 符号 (从 env 里面取值）
- 基本过程（直接调用基本过程的代码）
- 值类型 (primary type 直接取值)

以上的两个步骤可以被抽象为过程 eval 和 apply ，其中 eval 负责表达式的求值，apply 把一个过程对象应用于一组实际参数，这两者相互递归调用，eval 还有自递归。eval 和 apply 就像下图的这个像是太极图一样的图里，两者相互调用相互生成。

![eval-apply](learn-sicp-7/eval-apply.png)

#### 基础的递归解释器

整个 `eval` 和 `apply` 的过程直接看代码实现就可以了，这里可以看到 `eval` 的过程就是接受一个表达式 exp 和一个环境变量 env ，根据表达式类型的不同进行分别处理。

``` scheme
(define (eval exp env)
  (cond ((self-evaluating? exp) exp)                      ; 基本表达式
        ((variable? exp) (lookup-variable-value exp env)) ; 特殊形式
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ...                                               ; 组合形式
         (else (error "Unknown expression type: EVAL" exp))))
```

根据 exp 分情况来处理的过程，里面大概有三种类型的处理：

1. 基本表达式：包括能够自求值的表达式、变量
2. 各种特殊表达式：if、quote、lambda、cond 里面还会涉及到和 env 操作的部分
3. 过程结构：递归的对各个子表达式







这里用 `cond` 写了一个 `switch` 结构的过程，这对处理的逻辑顺序有很多的要求，不如使用数据分发的方式去

``` scheme
(define (apply procedure arguments)
  (cond ((primitive-procedure? procedure)
         (apply-primitive-procedure 
          procedure 
          arguments))
        ((compound-procedure? procedure)
         (eval-sequence
           (procedure-body procedure)
           (extend-environment
             (procedure-parameters 
              procedure)
             arguments
             (procedure-environment 
              procedure))))
        (else (error "Unknown procedure type: APPLY" procedure))))
```



## 总结

