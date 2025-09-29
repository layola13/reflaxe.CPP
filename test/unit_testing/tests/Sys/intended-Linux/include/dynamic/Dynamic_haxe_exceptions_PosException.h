#pragma once

#include "Dynamic.h"
namespace haxe {

class Dynamic_haxe_exceptions_PosException {
public:
	static Dynamic getProp(Dynamic& d, std::string name) {
		if(name == "toString") {
			return Dynamic::makeFunc<haxe::exceptions::PosException>(d, [](haxe::exceptions::PosException* o, std::deque<Dynamic> args) {
				return makeDynamic(o->toString());
			});
		}
		// call const version if none found here
		return getProp(static_cast<Dynamic const&>(d), name);
	}

	static Dynamic getProp(Dynamic const& d, std::string name) {
		if(name == "posInfos") {
			return Dynamic::unwrap<haxe::exceptions::PosException>(d, [](haxe::exceptions::PosException* o) {
				return makeDynamic(o->posInfos);
			});
		} else if(name == "==") {
			return Dynamic::makeFunc<haxe::exceptions::PosException>(d, [](haxe::exceptions::PosException* o, std::deque<Dynamic> args) {
				return makeDynamic((*o) == (args[0].asType<haxe::exceptions::PosException>()));
			});
		}
		return Dynamic();
	}

	static Dynamic setProp(Dynamic&, std::string, Dynamic) {
		return Dynamic();
	}
};

}