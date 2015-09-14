/*
* Released under the MIT License (MIT), http://opensource.org/licenses/MIT
*
* Copyright (c) 2014 Kåre Morstøl, NotTooBad Software (nottoobadsoftware.com)
*
* Contributors:
*	Kåre Morstøl, https://github.com/kareman - initial API and implementation.
*/

/**
This file contains operators and functions inspired by Functional Programming.
It can be used on its own.
*/

infix operator |> { precedence 50 associativity left }

public func |> <T,U> (lhs: T, rhs: T -> U) -> U {
	return rhs(lhs)
}

/** Lazily return a sequence containing the elements of source, in order, that satisfy the predicate includeElement */
public func filter <S : SequenceType>
	(includeElement: (S.Generator.Element) -> Bool)
	(source: S)
	-> LazySequence<FilterSequenceView<S>> {

		return lazy(source).filter(includeElement)
}

/**
Return an `Array` containing the sorted elements of `source` according to 'isOrderedBefore'.

Requires: `isOrderedBefore` is a `strict weak ordering
<http://en.wikipedia.org/wiki/Strict_weak_order#Strict_weak_orderings>` over `elements`.
*/
public func sorted <S : SequenceType>
	(isOrderedBefore: (S.Generator.Element, S.Generator.Element) -> Bool)
	(source: S)
	-> [S.Generator.Element] {

		return sorted(source, isOrderedBefore)
}

/** Lazily return a sequence containing the results of mapping transform over source. */
public func map <S: SequenceType, T>
	(transform: (S.Generator.Element) -> T)
	(source: S)
	-> LazySequence<MapSequenceView<S, T>> {

		return lazy(source).map(transform)
}

/**
Return the result of repeatedly calling combine with an accumulated value
initialized to initial and each element of sequence, in turn.
*/
public func reduce <S : SequenceType, U>
	(initial: U, combine: (U, S.Generator.Element) -> U)
	(sequence: S)
	-> U {

		return reduce(sequence, initial, combine)
}

/** Split text over delimiter, returning an array. */
public func split (_ delimiter: String = "\n")(text: String) -> [String] {
	return text.componentsSeparatedByString(delimiter)
}

/** Insert separator between each item in elements. */
public func join <C : ExtensibleCollectionType, S : SequenceType where S.Generator.Element == C>
	(separator: C)
	(elements: S)
	-> C {

		return join(separator, elements)
}

/** Turn a sequence into an array. For use after the |> operator. */
public func toArray <S : SequenceType> (sequence: S) -> [S.Generator.Element] {
	return Array(sequence)
}

/** Discard all elements in `tobedropped` from sequence. */
public func drop <S : SequenceType, T : Equatable where S.Generator.Element == T>
	(tobedropped: [T])
	(sequence: S)
	-> LazySequence<FilterSequenceView<S>> {
		
		return sequence |> filter { !contains(tobedropped, $0) }
}

/** Return at most the first `numbertotake` elements of sequence */
public func take <S : SequenceType, T where S.Generator.Element == T>
	(numbertotake: Int)(sequence: S) -> [T] {

		var generator = sequence.generate()
		var result = [T]()
		for _ in 0..<numbertotake {
			if let value = generator.next() {
				result.append(value)
			} else {
				break
			}
		}
		return result
}
