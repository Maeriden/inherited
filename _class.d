module inheritance._class;

import inheritance._meta, inheritance._virtual;


private template VirtualMethod(Self, alias decl)
{
	enum string selfPtr = "cast(" ~ decl.SelfType.stringof ~ "*)&this";
	enum string wrapperName = decl.Identifier[1..$];
	enum string self___vptr = "(cast(" ~ Self.stringof~".VTable*)this.__vptr)";
	
	enum string signature  = "auto " ~ wrapperName ~ "(Args...)(auto ref Args args)";
	enum string methodBody = "{ return "~self___vptr~"."~decl.Identifier~"("~selfPtr~", args); }";
	enum string statement = signature ~ methodBody;
	enum string VirtualMethod = statement;
	pragma(msg, Self.stringof~".VirtualMethod: "~statement);
}


// FIXME: Embedding this foreach in the DeclareVTable mixin causes a compilation error for no apparent reason
private mixin template DeclareVirtualMethods(Self)
{
	// pragma(msg, GetHierarchyVirtualDeclarations!Self);
	static foreach( alias decl; GetHierarchyVirtualDeclarations!Self )
	{
		mixin( VirtualMethod!(Self, decl) );
	}
}


private template VTableEntry(Self, alias decl)
{
	enum string ReturnType = decl.ReturnType.stringof;
	enum string Parameters = decl.Parameters.stringof;
	enum string Identifier = decl.Identifier;
	enum string Scope      = decl.SelfType.stringof;
	
	enum string statement = ReturnType~" function"~Parameters~" "~Identifier~" = &"~Scope~"."~Identifier~";";
	enum string VTableEntry = statement;
	pragma( msg, Self.stringof~".VTable.Entry: "~statement );
}


mixin template DeclareVTable(Self)
{
	static assert(is(Self == struct), "mixin DeclareVTable can only be used inside structs");
	
	static struct VTable
	{
		pragma(msg, Self,".VTable: ",GetHierarchyVirtualDeclarations!Self);
		static foreach( alias decl; GetHierarchyVirtualDeclarations!Self )
		{
			// mixin( VTableEntry!(Self, decl) );
			mixin( decl.ReturnType.stringof~" function"~decl.Parameters.stringof~" "~decl.Identifier~" = &"~decl.SelfType.stringof~"."~decl.Identifier~";" );
		}
	}
	
	static
	{
		immutable(Self.VTable) __vtbl;
	}
	
	mixin DeclareVirtualMethods!Self;
}



mixin template Inheritable()
{
	alias Self = typeof(this);
	static assert(__vptr.offsetof == 0, "struct "~Self.stringof~": mixin Inheritable must be the first declaration in the struct");
	
	mixin DeclareVTable!Self;
	immutable(void*) __vptr = &__vtbl;
}

mixin template Inherits(B)
{
	alias Self = typeof(this);
	alias Base = B;
	static assert( is(typeof(B.__vtbl)), "struct "~Self.stringof~" cannot inherit from struct "~Base.stringof~": base class does not support inheritance" );
	
	mixin DeclareVTable!Self;
	Base  base;
}



version(unittest)
{
	struct A {
		mixin Inheritable;
		
		@virtual static void* _foo(Self*) { return cast(void*)0; }
		@virtual static void* _bar(Self*) { return cast(void*)0; }
		@virtual static void* _baz(Self*) { return cast(void*)0; }
	}
	pragma(msg, "----------------------------------------------------");
	struct B {
		mixin Inherits!A;
		
		// @virtual static void* _foo(Self*) { return cast(void*)1; }
		@virtual static void* _bar(Self*) { return cast(void*)1; }
		@virtual static void* _baz(Self*) { return cast(void*)1; }
		@virtual static void* _asd(Self*) { return cast(void*)1; }
	}
	pragma(msg, "----------------------------------------------------");
	struct C {
		mixin Inherits!B;
		
		// @virtual static void* _foo(Self*) { return cast(void*)2; }
		// @virtual static void* _bar(Self*) { return cast(void*)2; }
		@virtual static void* _baz(Self*) { return cast(void*)2; }
		@virtual static void* _asd(Self*) { return cast(void*)2; }
		@virtual static void* _qwe(Self*) { return cast(void*)2; }
	}
	pragma(msg, "----------------------------------------------------");
}

unittest
{
	A a;
	assert(a.foo() == cast(void*)0);
	assert(a.bar() == cast(void*)0);
	assert(a.baz() == cast(void*)0);
	
	B b;
	assert(b.foo() == cast(void*)0);
	assert(b.bar() == cast(void*)1);
	assert(b.baz() == cast(void*)1);
	assert(b.asd() == cast(void*)1);
	
	C c;
	assert(c.foo() == cast(void*)0);
	assert(c.bar() == cast(void*)1);
	assert(c.baz() == cast(void*)2);
	assert(c.asd() == cast(void*)2);
	assert(c.qwe() == cast(void*)2);
}
