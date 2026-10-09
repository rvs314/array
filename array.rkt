#lang racket/base

(require racket/generic
         racket/sequence
         racket/flonum racket/fixnum racket/extflonum
         ffi/cvector
         ffi/vector
         (for-syntax racket/base racket/syntax syntax/parse))

(provide gen:array array?
         array-set! array-ref array-length array-copy! array-alloc
         array-empty? array-first array-last in-array
         array->list array->vector)

(begin-for-syntax
  ;; A type to register as an array: either a bare name, or a name with
  ;; flags saying whether to use its own `<type>-copy!` and `in-<type>`.
  ;; Without a flag, the function is used whenever it's bound.
  (define-syntax-class type-spec
    (pattern type:id
             #:attr copy? #f
             #:attr in? #f)
    (pattern [type:id (~alt (~optional (~seq #:copy? copy?:boolean)
                                       #:too-many "repeated #:copy? flag")
                            (~optional (~seq #:in? in?:boolean)
                                       #:too-many "repeated #:in? flag"))
                      ...])))

;; (define-generic-array name #:fast-defaults (type ...) #:defaults (type ...))
;; defines the generic interface gen:name, with methods named after `name`,
;; and registers each type as an instance of it.
(define-syntax (define-generic-array stx)
  (syntax-parse stx
    [(_ name:id
        #:fast-defaults (fast:type-spec ...)
        #:defaults (slow:type-spec ...))
     (define (method fs) (format-id #'name fs #'name))
     (with-syntax ([name-set!   (method "~a-set!")]
                   [name-ref    (method "~a-ref")]
                   [name-length (method "~a-length")]
                   [name-copy!  (method "~a-copy!")]
                   [name-alloc  (method "~a-alloc")]
                   [in-name     (method "in-~a")])
       (define (instance type copy? in?)
         (define (fmt fs) (format-id type fs type))
         (define (use? flag fs)
           (if flag
               (syntax-e flag)
               (and (identifier-binding (fmt fs)) #t)))
         #`[#,(fmt "~a?")
            (define name-set!   #,(fmt "~a-set!"))
            (define name-ref    #,(fmt "~a-ref"))
            (define name-length #,(fmt "~a-length"))
            (define (name-alloc _ len) (#,(fmt "make-~a") len))
            #,@(if (use? copy? "~a-copy!")
                   (list #`(define name-copy! #,(fmt "~a-copy!")))
                   '())
            #,@(if (use? in? "in-~a")
                   (list #`(define in-name #,(fmt "in-~a")))
                   '())])
       #`(define-generics name
           (name-set!   name idx value)
           (name-ref    name idx)
           (name-length name)
           (name-copy!  dest dest-start name [src-start] [src-end])
           (name-alloc  name len)
           (in-name     name)
           #:fallbacks
           [(define/generic len  name-length)
            (define/generic set! name-set!)
            (define/generic ref  name-ref)
            (define (name-copy! dest dest-start src
                                [src-start 0] [src-end (len src)])
              (for ([i (in-range src-start src-end)])
                (set! dest i (ref src i))))
            (define (in-name arr)
              (sequence-map
               (lambda (i) (ref arr i))
               (in-range (len arr))))]
           #:fast-defaults
           (#,@(map instance
                    (attribute fast.type)
                    (attribute fast.copy?)
                    (attribute fast.in?)))
           #:defaults
           (#,@(map instance
                    (attribute slow.type)
                    (attribute slow.copy?)
                    (attribute slow.in?)))))]))

(define-generic-array array
  #:fast-defaults (bytes vector string)
  #:defaults (flvector fxvector extflvector
              cvector s8vector
              u16vector s16vector
              u32vector s32vector
              u64vector s64vector
              f32vector f64vector f80vector))

(define (array-empty? arr)
  (zero? (array-length arr)))

(define (array-first arr)
  (array-ref arr 0))

(define (array-last arr)
  (array-ref arr (sub1 (array-length arr))))

(define (array->list arr)
  (for/list ([x (in-array arr)]) x))

(define (array->vector arr)
  (for/vector #:length (array-length arr) ([x (in-array arr)]) x))

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
