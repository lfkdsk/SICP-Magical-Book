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

### 基础的递归解释器

#### 核心 eval 和 apply

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
3. 过程结构：递归的对各个子表达式进行求值，然后 apply 应用过程

这里用 `cond` 写了一个 `switch` 结构的过程，这对处理的逻辑顺序有很多的要求，比如在一个 cond 的逻辑之中不同的分支的拜访位置不能有问题，不如使用数据分发的方式去设计这个 eval 的结构，还记得我们在第二章设计数据导向的 API 的时候做的事情么？首先是抽象一个 api 的表格：

``` scheme
; 操作／类型 ／过程
(put <op> <type> <item>)
; 操作／类型
(get <op> <type>)
```

然后给数据类型打上 tag 然后在使用前预先 install 对应的 api，这里我们甚至可以把不同类型的相同实现给出相同的名称，方便直接根据 data-type 去调用：

``` scheme
(define (install-rectangular-package)
; internal procedures
    (define (real-part z) (car z))
    (define (imag-part z) (cdr z))
  	; ... 省略其中的过程
    (put 'make-from-real-imag 'rectangular
        (lambda (x y) (tag (make-from-real-imag x y))))
    (put 'make-from-mag-ang 'rectangular
        (lambda (r a) (tag (make-from-mag-ang r a))))
'done)

```

不过暂时我们先不这么做，因为现在明显我们的 `eval` 和 `apply` 的过程是混杂在一起，我们并没有对 expr 进行相应的预处理给每种数据结构打上 tag，这里可以看到 `eval` 和 `apply` 的互生带来了解释器设计和实现上的便利，但是也在具体的效率、代码编写的规范和拓展性上有了一定的问题。

接着来看核心的 `apply` 过程吧，`apply` 的应用过程就简单了很多，把 `dispatch` 放到比较具体的调用环境：

``` scheme
(define (apply procedure arguments)
  (cond ((primitive-procedure? procedure) ; primary procedure
         (apply-primitive-procedure 
          procedure 
          arguments))
        ((compound-procedure? procedure)  ; compound procedure
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

1. primitive procedure 是 Scheme 里面也会出现的原生过程，这部分在 `apply` 的时候会直接下发给 Scheme 自带的 `apply procedure` ，因此我们在自己定义 `apply` 之前记得先保存下默认的实现。
2. compound-procedure 这个看起来也很简单，就是把各个 procedure 分别 eval 处理过之后又会回到 `apply` 过程之中，一个互生的调用又出现了。

####表达式处理和派生表达式

要是详细的介绍对各种表达式的处理过程未免失与琐碎，这里就只挑选一个有代表性的 `if` 语句来介绍处理过程，`if` 的具体 eval 实现过程如下：

``` scheme
(define (eval-if exp env)
  (if (true? (eval (if-predicate exp) env))
      (eval (if-consequent exp) env)
      (eval (if-alternative exp) env)))
```

这个过程非常的简单，其中的 `if-predicate` , `if-consequent` , `if-alternative` 都很不过是取出整个 `if-expr` 之中的不同部分的：

``` scheme
(define (if? exp) (tagged-list? exp 'if))
(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
      (cadddr exp)
      'false))
```

整个 `if` 的流程就这样拆解完了，根据 `predicate` 拆借出来的结果运算流程重新进入了 `eval` 投入了其他表达式类型的求值过程之中。这里使用 `if` 作为例子还有一个因素就是这个 DSL 实现之中的 `cond` 语句没有自己的具体实现逻辑，而是依赖组合的 `if` 实现的，这被称作派生表达式。

``` scheme
(define (cond? exp) 
  (tagged-list? exp 'cond))
(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) 
  (car clause))
(define (cond-actions clause) 
  (cdr clause))
(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))
(define (expand-clauses clauses)
  (if (null? clauses)
      'false     ; no else clause
      (let ((first (car clauses))
            (rest (cdr clauses)))
        (if (cond-else-clause? first)
            (if (null? rest)
                (sequence->exp 
                 (cond-actions first))
                (error "ELSE clause isn't 
                        last: COND->IF"
                       clauses))
            (make-if (cond-predicate first)
                     (sequence->exp 
                      (cond-actions first))
                     (expand-clauses 
                      rest))))))
```

上面这段代码比较核心的也就是 `cond->if` 相关的函数了，但是也非常的简单就是解析 `cond` 的结构，层层解析然后通过 `make->if` 生成逐级的 `nested-if` 。

#### 解释器环境操作

解释器的运行环境和我们在第一章、第二章里面解释过的运行环境基本上是一个东西，这不过这里面我们要来手动实现这个环境。这里我们把环境理解为绑定参数的表格就好了。这里给出了环境提供的默认的几个 API：

``` scheme
(lookup-variable-value ⟨var⟩ ⟨env⟩)

(extend-environment ⟨variables⟩ ⟨values⟩ ⟨base-env⟩)

(define-variable! ⟨var⟩ ⟨value⟩ ⟨env⟩)

(set-variable-value! ⟨var⟩ ⟨value⟩ ⟨env⟩)
```

1. 其中的 `lookup-variable-value` 负责了在环境之中查找对应的变量，而  `extend-environment` 则是在根据上级环境来拓展新的 env。
2. `define-variable!` 和 `set-variable-value!` 这一对 API 就比较简单了在环境之中定义变量和修改变量。

> Tips 基础递归解释器的 [源码](<https://github.com/lfkdsk/SICP-Magical-Book/blob/master/code/meta-evaluator/evaluator.rkt>)：
>
> 这里给出了基础的递归解释器的实现代码，这里的程序可以直接使用 `racket` 运行，记得要安装 `sicp` 的包。
>
> PS：这里还有一个问题，就是之前提到要提前把 `apply` 方法保存起来，但是如果保存的过程和 `apply` 的定义同时出现在一个文件里，就会被 `racket` 认为是提前使用未定义方法 orz，因此这里我们单独把这个方法单独提出到一个文件里面引用了。

### 以数据作为程序




## 总结

