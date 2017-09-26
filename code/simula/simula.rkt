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


(define input-1 (make-wire)) 
(define input-2 (make-wire))

(define sum (make-wire)) 
(define carry (make-wire))

(probe 'sum sum)
(probe 'carry carry)

