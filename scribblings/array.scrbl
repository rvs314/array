#lang scribble/manual

@require[@for-label[array racket/base racket/flonum ffi/cvector ffi/vector]]

@title{array: Generic and Dynamic Arrays}
@author{rvs314}

@defmodule[array]

@(define (ref thing)
   (tech #:doc '(lib "scribblings/reference/reference.scrbl") thing))

The @racketmodname[array] module provides a @ref{generic interface} for the @deftech{array}, a data structure that uses compact, constant-time, natural-number indexing and updating. Racket has many built-in types which act as either homogeneous (all elements have the same type) or heterogeneous (elements can have different types) @tech{array}s, such as the @ref{vector}, @ref{byte string}, @ref{string}, @ref{flvector}, and others. This module also provides an implementation of the @tech{dynamic array}, an @tech{array} which grows exponentially, allowing for an amortized @math{O(1)} append operation.

@section{Generic Arrays}

@defidform[gen:array]{

A @ref{generic interface} for arrays. The interface defines the following methods:

@itemlist[@item{@racket[array-set!]}
          @item{@racket[array-ref]}
          @item{@racket[array-length]}
          @item{@racket[array-alloc]}
          @item{@racket[array-copy!]}
          @item{@racket[in-array]}]

}

@defproc[(array? [obj any/c]) boolean?]{
Returns @racket[#t] if the object implements the @racket[gen:array] interface, @racket[#f] otherwise. 

}

@defproc[(array-set! [array array?] [idx exact-nonnegative-integer?] [val any/c]) void?]{
Sets slot @racket[idx] of @racket[array] to be @racket[val].
}

@defproc[(array-ref [array array?] [idx exact-nonnegative-integer?]) any/c]{
Returns slot @racket[idx] of @racket[array].
}

@defproc[(array-length [array array?]) exact-nonnegative-integer?]{
Returns the number of valid slots in @racket[array].
}

@defproc[(array-alloc [array array?] [len exact-nonnegative-integer?]) array?]{
Returns a new array of the same type as @racket[array] with @racket[len] elements. The elements of the returned array are not defined. 
}

@defproc[(array-copy! [dest array?] [dest-start exact-nonnegative-integer?] [array array?] [array-start exact-nonnegative-integer? 0] [array-end exact-nonnegative-integer? (array-length array)]) void?]{
Changes the elements of @racket[dest] starting at position @racket[dest-start] to match the elements in @racket[array] from @racket[array-start] (inclusive) to @racket[array-end] (exclusive). There is a fallback implementation for this method.
}

@defproc[(in-array [array array?]) sequence?]{
Returns a sequence containing all the elements of @racket[array]. There is a fallback implementation for this method. Using this is often faster than indexing each element individually, as it avoids redundant method lookups.
}

@defproc[(array-empty? [array array?]) boolean?]{
Returns @racket[#t] if @racket[array] has a length of zero, @racket[#f] otherwise.
}

@defproc[(array-first [array array?]) any/c]{
Returns the element at index zero of @racket[array].
}

@defproc[(array-last [array array?]) any/c]{
Returns the element at index @racket[(sub1 (array-length array))] of @racket[array].
}

@defproc[(array->list [array array?]) list?]{
Returns the elements of @racket[array] as a newly allocated list.
}

@defproc[(array->vector [array array?]) vector?]{
Returns the elements of @racket[array] as a newly allocated vector.
}

@section{Dynamic Arrays}

@defmodule[array/dynamic]

@defstruct*[dynamic-array ([buffer array?] [length exact-nonnegative-integer?])]{
A @deftech{dynamic array} (also called an @deftech{array-list} or @deftech{growable array}) is an array that can grow in amortized @math{O(1)} time. It's implemented using a traditional, static @tech{array} (called the @racket[dynamic-array-buffer]), where only the first @racket[dynamic-array-length] elements are meaningful. By increasing the length field of the @tech{dynamic array}, we can increase the number of elements until we run out of space in the underlying buffer, in which case we allocate a new underlying buffer and continue. Notice that for a given @tech{dynamic array} @racket[arr], @racket[(dynamic-array-length arr)] is not the same as @racket[(array-length (dynamic-array-buffer arr))].
}

@defproc[(dynamic-array? [obj any/c]) boolean?]{
Returns @racket[#t] if @racket[obj] is an instance of the @racket[dynamic-array] structure type, @racket[#f] otherwise.
}

@defproc[(dynamic-array [arr array?] [len exact-nonnegative-integer? (array-length arr)]) dynamic-array?]{
Returns a new @tech{dynamic array}.
}

@defproc[(dynamic-array-buffer [array dynamic-array?]) array?]{
Returns the underling buffer of the @tech{dynamic array} @racket[array].
}

@defproc[(dynamic-array-length [array dynamic-array?]) exact-nonnegative-integer?]{
Returns the length of the @tech{dynamic array} @racket[array].
}

@defproc[(dynamic-array-capacity [array dynamic-array?]) exact-nonnegative-integer?]{
Returns the capacity of the @tech{dynamic array} @racket[array]. This is increased automatically by @racket[dynamic-array-append!] and @racket[dynamic-array-push!] and can be increased manually by calling @racket[dynamic-array-ensure-capacity!].
}

@defproc[(dynamic-array-ensure-capacity [array dynamic-array?] [min-cap exact-nonnegative-integer?]) void?]{
Grows the underlying buffer of @racket[array] until it has a capacity of at least @racket[min-cap].
}

@defproc[(dynamic-array-append! [array dynamic-array?] [new-values array?]) void?]{
Pushes an @tech{array} of new values onto the @racket[array]. This will cause at most one new allocation.
}

@defproc[(dynamic-array-push! [array dynamic-array?] [new-value any/c]) exact-nonnegative-integer?]{
Pushes a new values onto the @racket[array]. This will cause at most one new allocation. Returns the index of the element pushed.
}

@defproc[(dynamic-array-pop! [array dynamic-array?]) any/c]{
Returns the last element of @racket[array] and decreases the @racket[dynamic-array-length] by one. Raises an @racket[exn:fail:contract] if the array is empty. 
}

@defproc[(dynamic-array-contents [array dynamic-array?]) array?]{
Returns a newly allocated @tech{array} of the same type as @racket[(dynamic-array-buffer array)] with the contents of @racket[array].
}
