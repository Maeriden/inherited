module inheritance._meta;

/**
 * Allows `alias`ing of any single symbol, type or compile-time expression.
 *
 * Not everything can be directly aliased. An alias cannot be declared of - for example - a literal:
 * ---
 * alias a = 4; //Error
 * ---
 * With this template any single entity can be aliased:
 * ---
 * alias b = Alias!4; //OK
 */
alias Alias(alias a) = a;


/**
 * Creates a sequence of zero or more aliases. This is most commonly used as template parameters or arguments.
 */
alias AliasTuple(T...) = T;


// alias Identifier(alias s)       = Alias!(     __traits(identifier,    s));
// alias GetMember(T, alias s)     = Alias!(     __traits(getMember,  T, s));
// alias AllMembers(T)             = AliasTuple!(__traits(allMembers, T   ));
// alias AllIdentifiers(T)         = AllMembers!T;

enum IsStaticFunction(alias s) = __traits(isStaticFunction, s);



/// Calls F with each Arg.
/// Returns an AliasTuple of all the results of F.
template MetaMap(alias F, Args...)
{
	version(META_DEBUG) pragma( msg, "MetaMap(",F.stringof,", ",Args.stringof,")" );
	
	static if(Args.length)
		alias MetaMap = AliasTuple!( F!(Args[0]), MetaMap!(F, Args[1..$]) );
	else
		alias MetaMap = AliasTuple!();
}
// unittest
// {
// 	struct A {
// 		long _id;
// 		void foo();
// 	}
	
// 	static assert( MetaMap!(Identifier, AllSymbols!A) == AliasTuple!("_id", "foo") );
// }



/// Calls F with each Arg.
/// Returns an AliasTuple of all those Args for which F evaluated to true.
template MetaFilter(alias F, Args...)
{
	version(META_DEBUG) pragma( msg, "MetaFilter(",F.stringof,", ",Args.stringof,")" );
	
	static if( Args.length )
	{
		static if( F!(Args[0]) )
			alias MetaFilter = AliasTuple!( Args[0], MetaFilter!(F, Args[1..$]) );
		else
			alias MetaFilter = MetaFilter!(F, Args[1..$]);
	}
	else
	{
		alias MetaFilter = AliasTuple!();
	}
}
// unittest
// {
// 	struct A {
// 		long _id;
// 		void foo();
// 		void bar();
// 	}
	
// 	alias filtered = MetaFilter!(IsFoo, AllSymbols!A);
// 	alias comparable = MetaMap!( Identifier, filtered );
// 	static assert( comparable == AliasTuple!("foo") );
// }
// version(unittest) private enum IsFoo(alias symbol) = Identifier!symbol == "foo";



template MetaFold(alias F, alias first, rest...)
{
	version(META_DEBUG) pragma( msg, "MetaFold(",F.stringof,", ",first.stringof,", ",rest.stringof,")" );
	
	static if( rest.length )
		alias MetaFold = MetaFold!( F, F!( first, rest[0] ), rest[1..$] );
	else
		alias MetaFold = first;
}



template MetaContains(alias cmp, alias needle, haystack...)
{
	version(META_DEBUG) pragma( msg, "MetaContains(",cmp.stringof,", ",needle.stringof,", ",haystack.stringof,")" );
	
	static if( haystack.length )
	{
		static if( cmp!(needle, haystack[0]) )
			enum bool MetaContains = true;
		else
			enum bool MetaContains = MetaContains!( cmp, needle, haystack[1..$] );
	}
	else
	{
		enum bool MetaContains = false;
	}
}



template MetaIsUnique(alias cmp, alias elem, collection...)
{
	version(META_DEBUG) pragma( msg, "MetaIsUnique(",cmp.stringof,", ",elem.stringof,", ",collection.stringof,")" );
	
	static if( collection.length )
	{
		static if( cmp!(elem, collection[0]) )
			enum bool MetaIsUnique = false;
		else
			enum bool MetaIsUnique = MetaIsUnique!( cmp, elem, collection[1..$] );
	}
	else
	{
		enum bool MetaIsUnique = true;
	}
}



template AllSymbols(T)
{
	version(META_DEBUG) pragma( msg, "AllSymbols(",T,")" );
	
	template GetSymbol(string ident)
	{
		version(META_DEBUG) pragma( msg, "AllSymbols(",T,").GetSymbol(",ident,")" );
		
		static if( is( typeof(__traits(getMember, T, ident)) ) )
			alias GetSymbol = AliasTuple!( __traits(getMember, T, ident) );
		else
			alias GetSymbol = AliasTuple!();
	}
	
	alias AllSymbols = MetaMap!( GetSymbol, __traits(allMembers, T) );
}
// unittest
// {
// 	struct A { }
// 	struct B {
// 		int  a;
// 		void foo();
// 		int  bar(int);
// 	}
	
// 	alias allSymbols_A = AliasTuple!();
// 	alias allSymbols_B = AliasTuple!(B.a, B.foo, B.bar);
	
// 	// pragma( msg, AllSymbols!B .stringof );
// 	// pragma( msg, allSymbols_B .stringof );
// 	// pragma( msg, allSymbols_A .stringof );
	
// 	static assert( is( AllSymbols!A == allSymbols_A  ));
// 	static assert(!is( AllSymbols!B == AliasTuple!() ));
// 	// FIXME: AliasTuples dont compare equal
// 	// static assert( is( AllSymbols!B == AllSymbols!B  ));
// }
