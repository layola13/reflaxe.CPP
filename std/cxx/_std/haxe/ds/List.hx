package haxe.ds;

@:cxxStd
@:haxeStd
@:coreApi
class List<T> {
	private var h:Null<ListNode<T>>;
	private var q:Null<ListNode<T>>;
	public var length(default, null):Int;

	public function new():Void {
		length = 0;
	}

	public function add(item:T):Void {
		var x = new ListNode(item, null);
		if (h == null)
			h = x;
		else
			q.next = x;
		q = x;
		length++;
	}

	public function push(item:T):Void {
		var x = new ListNode(item, h);
		h = x;
		if (q == null)
			q = x;
		length++;
	}

	public function first():Null<T> {
		return if (h == null) null else h.item;
	}

	public function last():Null<T> {
		return if (q == null) null else q.item;
	}

	public function pop():Null<T> {
		if (h == null)
			return null;
		var x = h.item;
		h = h.next;
		if (h == null)
			q = null;
		length--;
		return x;
	}

	public function isEmpty():Bool {
		return (h == null);
	}

	public function clear():Void {
		h = null;
		q = null;
		length = 0;
	}

	public function remove(v:T):Bool {
		var prev:ListNode<T> = null;
		var l = h;
		while (l != null) {
			if (l.item == v) {
				if (prev == null)
					h = l.next;
				else
					prev.next = l.next;
				if (q == l)
					q = prev;
				length--;
				return true;
			}
			prev = l;
			l = l.next;
		}
		return false;
	}

	public inline function iterator():ListIterator<T> {
		return new ListIterator<T>(h);
	}

	@:pure @:runtime public inline function keyValueIterator():ListKeyValueIterator<T> {
		return new ListKeyValueIterator(h);
	}

	public function toString():String {
		var s = new StringBuf();
		var first = true;
		var l = h;
		s.add("{");
		while (l != null) {
			if (first)
				first = false;
			else
				s.add(", ");
			s.add(Std.string(l.item));
			l = l.next;
		}
		s.add("}");
		return s.toString();
	}

	public function join(sep:String):String {
		var s = new StringBuf();
		var first = true;
		var l = h;
		while (l != null) {
			if (first)
				first = false;
			else
				s.add(sep);
			s.add(l.item);
			l = l.next;
		}
		return s.toString();
	}

	public function filter(f:T->Bool):List<T> {
		var l2 = new List();
		var l = h;
		while (l != null) {
			var v = l.item;
			l = l.next;
			if (f(v))
				l2.add(v);
		}
		return l2;
	}

	public function map<X>(f:T->X):List<X> {
		var b = new List();
		var l = h;
		while (l != null) {
			var v = l.item;
			l = l.next;
			b.add(f(v));
		}
		return b;
	}
}

@:cxxStd
private class ListNode<T> {
	public var item:T;
	public var next:ListNode<T>;

	public function new(item:T, next:ListNode<T>) {
		this.item = item;
		this.next = next;
	}
}

@:cxxStd
private class ListIterator<T> {
	var head:ListNode<T>;

	public inline function new(head:ListNode<T>) {
		this.head = head;
	}

	public inline function hasNext():Bool {
		return head != null;
	}

	public inline function next():T {
		var val = head.item;
		head = head.next;
		return val;
	}
}

@:cxxStd
private class ListKeyValueIterator<T> {
	var idx:Int;
	var head:ListNode<T>;

	public inline function new(head:ListNode<T>) {
		this.head = head;
		this.idx = 0;
	}

	public inline function hasNext():Bool {
		return head != null;
	}

	public inline function next():{key:Int, value:T} {
		var val = head.item;
		head = head.next;
		return {value: val, key: idx++};
	}
}