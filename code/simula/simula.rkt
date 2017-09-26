;;; simula

(load "gate.rkt")
(load "adder.rkt")
(load "wire.rkt")
(load "agenda.rkt")
(load "prob.rkt")

(define the-agenda (make-agenda))
(define inverter-delay 2)
(define and-gate-delay 3)
(define or-gate-delay 5)



