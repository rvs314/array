#lang racket

(require racket/generic
         racket/flonum racket/fixnum racket/extflonum
         ffi/cvector
         ffi/vector
         (for-syntax racket/syntax))

(provide gen:array array?
         array-set! array-ref array-length array-copy! array-alloc
         array-empty? array-first array-last in-array
         array->list array->vector)

(define-syntax (define-generic-array stx)
  (define-syntax-rule (with-names (name ...) body ...)
    (with-syntax ([name (datum->syntax stx 'name)] ...)
      body ...))
  (syntax-case stx ()
    [(_)
     (with-names (array array-set! array-ref array-length
                        array-copy! array-alloc in-array) 
       (define default-types
         (syntax->list #'(cvector u8vector s8vector
                                  u16vector s16vector
                                  u32vector s32vector
                                  u64vector s64vector
                                  f32vector f64vector f80vector)))
       (define (array-definition name [copy #f] [in #f])
         (define (fmt str [n name])
           (format-id n str n))
         (define (def fs [rst #f]) #`(define #,(fmt fs #'array) #,(or rst (fmt fs name))))
         #`[#,(fmt "~a?")
            #,(def "~a-set!")
            #,(def "~a-ref")
            #,(def "~a-length")
            #,(def "~a-alloc"
                #`(lambda (_ arg)
                    (#,(fmt "make-~a") arg)))
            #,@(cond [(eq? #t copy) (list (def "~a-copy!"))]
                     [(not copy)    (list)]
                     [else          (list copy)])
            #,@(cond [(eq? #t in)   (list (def "in-~a"))]
                     [(not in)      (list)]
                     [else          (list in)])])
       #`(define-generics array
           (array-set!   array idx value)
           (array-ref    array idx)
           (array-length array)
           (array-copy!  dest dest-start array [array-start] [array-end])
           (array-alloc  array len)
           (in-array     array)
           #:fallbacks
           [(define/generic len  array-length)
            (define/generic set! array-set!)
            (define/generic ref  array-ref)
            (define (array-copy! dest dest-start array
                                 [array-start 0] [array-end (len array)])
              (for ([i (in-range array-start array-end)])
                (set! dest i (ref array i))))
            (define (in-array arr)
              (sequence-map
               (lambda (i) (ref arr i))
               (in-range (len arr))))]
           #:fast-defaults
           (#,(array-definition #'bytes  #t #t)
            #,(array-definition #'vector #t #t)
            #,(array-definition #'string #t #t))
           #:defaults
           (#,(array-definition #'flvector #f #t)
            #,(array-definition #'fxvector #f #t)
            #,(array-definition #'extflvector #f #t)
            #,(array-definition #'u8vector #'bytes-copy! #'in-bytes)
            #,@(map array-definition default-types))))]))

(define-generic-array)
          
(define (array-empty? arr)
 (zero? (array-length arr)))

(define (array-first arr)
  (array-ref arr 0))

(define (array-last arr)
  (array-ref arr (sub1 (array-length arr))))

(define (array->list arr)
  (sequence->list (in-array arr)))

(define (array->vector arr)
  (define v (make-vector (array-length arr)))
  (for ([i (in-naturals)]
        [o (in-array arr)])
    (vector-set! v i o))
  v)

(module+ test
  (require rackunit)

  (check-equal? (array->vector "alphabet")
                '#(#\a #\l #\p #\h #\a #\b #\e #\t))

  (check-equal? (array->vector (u32vector 0 1 3 2 4))
                '#(0 1 3 2 4))

  (check-equal? (array->list (u8vector 0 1 32 2 2))
                '(0 1 32 2 2))

  (define foo (u8vector 2 40 21 3))
  (array-copy! foo 2 (u8vector 9 12))
  (check-equal? (u8vector 2 40 9 12) foo)

  (check-equal? (array-alloc foo 5)
                (u8vector 0 0 0 0 0)))
