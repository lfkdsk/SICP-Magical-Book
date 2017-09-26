; 创建一条连线
(define (make-wire)
  (let ((signal-value 0)
        (action-proceduers '()))
    ; set new value and call proceduers
    (define (set-my-signal! new-value)
      (if (not (= signal-value new-value))
          (begin (set! signal-value new-value)
                 (call-each aciton-proceduers))
          'done))
    (define (accept-action-proceduer! proc)
      (set! action-proceduers
            (cons proc action-proceduers))
      (proc))
    (define (dispatch m)
      (cond ((eq? m 'get-signal) signal-value)
            ((eq? m 'set-signal!) set-my-signal!)
            ((eq? m 'add-action!) accept-action-proceduer!)
            (else (error "Unknown operation -- WIRE" m))))
    dispatch))

; 遍历调用
(define (call-each proceduers)
  (if (null? procedures)
      'done
      (begin
        ((car proceduers))
        (call-each (cdr procedures)))))

(define (get-signal wire)
    (wire 'get-signal))

(define (set-signal! wire new-value)
    ((wire 'set-signal!) new-value))

(define (add-action! wire action-procedure)
    ((wire 'add-action!) action-procedure))
