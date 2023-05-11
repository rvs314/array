#lang racket

(require "array.rkt" racket/generic)

(provide (except-out (struct-out dynamic-array) dynamic-array)
         (rename-out [new-dynamic-array dynamic-array])
         dynamic-array-capacity dynamic-array-ensure-capacity!
         dynamic-array-append! dynamic-array-push! dynamic-array-pop!
         dynamic-array-contents)

(struct dynamic-array (buffer length)
  #:mutable
  #:methods gen:custom-write
  [(define (write-proc me port mode)
     (define v (dynamic-array-contents me))
     (case mode
       [(#t)  (write v port)]
       [(#f)  (display v port)]
       [(0 1) (print v port mode)]))]
  #:methods gen:equal-mode+hash
  [(define (equal-mode-proc me them rec just-for-now?)
     (if just-for-now?
         (and (= (dynamic-array-length me) (dynamic-array-length them))
              (for/and ([m (in-array me)]
                        [t (in-array them)])
                (rec m t)))
         (eq? me them)))
   (define (hash-mode-proc me rec just-for-now?)
     (if just-for-now?
         (rec (dynamic-array-contents me))
         (eq-hash-code me)))]
  #:methods gen:array
  [(define/generic len array-length)
   (define/generic ref array-ref)
   (define/generic set! array-set!)
   (define/generic copy! array-copy!)
   (define/generic alloc array-alloc)
   (define/generic in in-array)
   (define (array-length arr)
     (dynamic-array-length arr))
   (define (array-ref array idx)
     (ref (dynamic-array-buffer array) idx))
   (define (array-set! array idx val)
     (set! (dynamic-array-buffer array) idx val)) 
   (define (array-copy! dest dest-start array
                        [array-start 0] [array-end (dynamic-array-length array)])
     (copy! dest dest-start (dynamic-array-buffer array)
            array-start array-end))
   (define (array-alloc array len)
     (dynamic-array (alloc (dynamic-array-buffer array) len) len))
   (define (in-array arr)
     (stream-take (sequence->stream (in (dynamic-array-buffer arr)))
                  (dynamic-array-length arr)))])

(define (new-dynamic-array arr [len (array-length arr)])
  (when (> len (array-length arr))
    (raise-argument-error
     'dynamic-array
     "a dynamic array length less than that of the underlying buffer"
     1 arr len))
  (dynamic-array arr len))

(define (dynamic-array-capacity arr)
  (array-length (dynamic-array-buffer arr)))

(define minimum-dynamic-array-cacpacity 8)

(define (dynamic-array-ensure-capacity! arr min-cap)
  (define new-cap (let loop ([cap (dynamic-array-capacity arr)])
                    (if (< cap min-cap)
                        (loop (max minimum-dynamic-array-cacpacity (floor (* 3/2 cap))))
                        cap))) 
  (unless (= new-cap (dynamic-array-capacity arr))
    (define new-buff (array-alloc (dynamic-array-buffer arr) new-cap))
    (array-copy! new-buff 0 (dynamic-array-buffer arr)
                 0 (dynamic-array-length arr))
    (set-dynamic-array-buffer! arr new-buff)))

(define (dynamic-array-append! arr new-values)
  (define new-len (+ (dynamic-array-length arr)
                     (array-length new-values)))
  (dynamic-array-ensure-capacity! arr new-len)
  (array-copy! (dynamic-array-buffer arr) (dynamic-array-length arr) new-values) 
  (set-dynamic-array-length! arr new-len))

(define (dynamic-array-push! arr new-value)
  (dynamic-array-ensure-capacity! arr (add1 (dynamic-array-length arr)))
  (set-dynamic-array-length! arr (add1 (dynamic-array-length arr)))
  (array-set! arr (sub1 (dynamic-array-length arr)) new-value))

(define (dynamic-array-pop! arr)
  (when (array-empty? arr)
    (raise-argument-error 'dynamic-array-pop! "a non-empty array" 0 arr))
  (set-dynamic-array-length! arr (sub1 (dynamic-array-length arr)))
  (array-ref arr (dynamic-array-length arr)))

(define (dynamic-array-contents arr)
  (define res (array-alloc (dynamic-array-buffer arr)
                           (dynamic-array-length arr)))
  (array-copy! res 0 (dynamic-array-buffer arr) 0 (dynamic-array-length arr))
  res)

(module+ test
  (require rackunit)

  (define da (new-dynamic-array "four"))

  (check-equal? da da)
  (check equal-always? da da)
  (check-equal? (equal-hash-code da) (equal-hash-code da))

  (define db (new-dynamic-array "four"))

  (check-equal? da db)
  (check (negate equal-always?) da db)
  (check-equal? (equal-hash-code da) (equal-hash-code db))
  (check (negate equal?) (equal-always-hash-code da) (equal-always-hash-code db))

  (check-equal? (dynamic-array-contents db) "four")
  (dynamic-array-push! db #\t)
  (check-equal? (dynamic-array-contents db) "fourt")
  (dynamic-array-append! db "hy")
  (check-equal? (dynamic-array-contents db) "fourthy")

  (check-equal? (dynamic-array-pop! db) #\y)
  (check-equal? (dynamic-array-contents db) "fourth"))
