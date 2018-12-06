module inheritance._virtual;

import inheritance._meta;
import std.traits : FuncReturnType = ReturnType, FuncParamsType = ParameterTypeTuple, hasUDA;

// Attribute for virtual function
// Marking a function virtual will cause a vtable entry to be generated for it
struct virtual {}


// Information returned by the templates in this module
struct VirtualDeclaration(Scope, alias symbol)
{
	static assert(hasUDA!(symbol, virtual), "Cannot create a VirtualDeclaration for non-@virtual symbol "~symbol.stringof);
	
	alias Symbol     = symbol;
	alias Type       = typeof(symbol);
	alias SelfType   = Scope;
	enum  Identifier = __traits(identifier, symbol);
	alias ReturnType = FuncReturnType!Symbol;
	alias Parameters = FuncParamsType!Symbol;
}



private template IsDescendant(T, Ancestor)
{
	version(META_DEBUG) pragma( msg, "IsDescendant(",T,", ",Ancestor,")" );
	
	static if( is(typeof(T.base) BaseType) )
	{
		static if( is(BaseType == Ancestor) )
			enum bool IsDescendant = true;
		else
			enum bool IsDescendant = IsDescendant!( BaseType, Ancestor );
	}
	else
	{
		enum bool IsDescendant = false;
	}
}



private template IsOverride(alias base, alias over)
{
	version(META_DEBUG) pragma( msg, "IsOverride(",over.stringof,", ",base.stringof,")" );
	
	enum bool sameIdentifier  = over.Identifier == base.Identifier;
	enum bool sameParameters  = is(over.Parameters[1..$] == base.Parameters[1..$]);
	enum bool selfConvertible = IsDescendant!(over.SelfType, base.SelfType);
	
	enum IsOverride = sameIdentifier && sameParameters && selfConvertible;
	version(META_DEBUG) pragma( msg, "    IsOverride(",over.stringof,", ",base.stringof,") = ",IsOverride," (",sameIdentifier,", ",sameParameters,", ",selfConvertible,")" );
}



private template IsVirtualSymbol(alias symbol)
{
	enum bool IsVirtualSymbol = /+is(typeof(symbol)) &&+/ IsStaticFunction!symbol && hasUDA!(symbol, virtual);
}



private template GetVirtualDeclarations(T)
{
	version(META_DEBUG) pragma( msg, "GetVirtualDeclarations(",T,")" );
	
	alias ToDeclaration(alias symbol) = VirtualDeclaration!(T, symbol);
	
	alias allSymbols = AllSymbols!T;
	version(META_DEBUG) pragma( msg, "    AllSymbols(",T,") = ",allSymbols.stringof );
	alias allVirtualSymbols = MetaFilter!( IsVirtualSymbol, allSymbols );
	version(META_DEBUG) pragma( msg, "    allVirtualSymbols = ",allVirtualSymbols.stringof );
	alias GetVirtualDeclarations = MetaMap!( ToDeclaration, allVirtualSymbols );
}



template GetHierarchyVirtualDeclarations(T)
{
	version(META_DEBUG) pragma( msg, "GetHiearchyVirtualDeclarations(",T,")" );
	
	template TraverseHierarchy(Scope, descDeclarations...)
	{
		version(META_DEBUG) pragma( msg, "GetHiearchyVirtualDeclarations(",T,").TraverseHierarchy(",Scope,", ",descDeclarations.stringof,")" );
		
		alias selfDeclarations = GetVirtualDeclarations!Scope;
		version(META_DEBUG) pragma( msg, "    selfDeclarations(",Scope,") = ",selfDeclarations.stringof );
		
		enum bool NewDeclaration(alias decl) = !MetaContains!( IsOverride, decl, descDeclarations );
		alias newDeclarations = MetaFilter!( NewDeclaration, selfDeclarations );
		version(META_DEBUG) pragma( msg, "    newDeclarations(",Scope,") = ",newDeclarations.stringof );
		
		static if( is(typeof(Scope.base) B) )
			alias TraverseHierarchy = TraverseHierarchy!( B, newDeclarations, descDeclarations );
		else
			alias TraverseHierarchy = AliasTuple!( newDeclarations, descDeclarations );
	}
	
	alias GetHierarchyVirtualDeclarations = TraverseHierarchy!T;
}
