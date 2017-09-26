
; 算数逻辑非
(define (logical-not s)
  (cond ((= s 0) 1)
        ((= s 1) 0)
        (else (error " Invalid signal " s))))

; 算数逻辑与
(define (logical-and a b)
  (if (and (= a 1) (= b 1))
      1
      0))
      

; 逻辑或
(define (logical-or a b)
  (if (or (= a 1) (= b 1))
      1
      0))

; 与门 给两个线路都绑上一个监控器
; 当某个值变化的时候 会重新计算 new-value 设置到输出端口
(define (and-gate a1 a2 output)
  (define (and-action-procedure)
    (let ((new-value
           (logical-and (get-signal a1) (get-signal a2))))
      (after-delay and-gate-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! a1 and-action-procedure)
  (add-action! a2 and-action-procedure)
  'ok)

; 或门 
(define (or-gate input-1 input-2 output)
  (define (or-action-procedure)
    (let ((new-value
           (logical-or (get-signal input-1) (get-signal input-2))))
      (after-delay or-gate-delay
                   (lambda ()
                     (set-signal! output new-value)))))
    (add-action! input-1 or-action-procedure)
    (add-action! input-2 or-action-procedure)
    'ok)

; 反门
(define (inverter-gate input output)
  (define (invert-input)
    (let ((new-value (logical-not (get-signal input))))
      (after-delay inverter-delay
                   (lambda () (set-signal! output new-value)))))
  (add-action! input invert-input)
  'ok)

              