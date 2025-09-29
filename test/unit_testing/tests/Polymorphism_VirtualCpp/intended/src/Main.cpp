#include "Main.h"

#include <cstdlib>
#include <memory>

void _Main::Main_Fields_::main() {
	std::shared_ptr<Base> b = std::make_shared<Base>();
	std::shared_ptr<Child> c = std::make_shared<Child>();
	std::shared_ptr<Base> b2 = std::static_pointer_cast<Base>(c);

	if(b->getVal() != 1) {
		exit(1);
	};
	if(c->getVal() != 2) {
		exit(1);
	};
	if(b2->getVal() != 2) {
		exit(1);
	};
	if(b2->getVal2() != 999) {
		exit(1);
	};
}
Base::Base():
	_order_id(generate_order_id())
{

}

int Base::getVal() {
	return 1;
}

int Base::getVal2() {
	return 999;
}
Child::Child():
	Base(), _order_id(generate_order_id())
{

}

int Child::getVal() {
	return 2;
}
