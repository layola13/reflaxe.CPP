#pragma once

#include <deque>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include "Std.h"

class HxArray {
public:
	template<typename T>
	static std::shared_ptr<std::deque<T>> concat(std::deque<T>* a, std::deque<T>* other) {
		std::shared_ptr<std::deque<T>> tempArray;

		{
			std::shared_ptr<std::deque<T>> result = std::make_shared<std::deque<T>>(std::deque<T>{});

			{
				int _g = 0;
				std::deque<T>* _g1 = a;

				while(_g < (int)(_g1->size())) {
					T obj = (*_g1)[_g];

					++_g;

					{
						result->push_back(obj);
					};
				};
			};

			tempArray = result;
		};

		int _g_current = 0;
		std::deque<T>* _g_array = other;

		while(_g_current < (int)(_g_array->size())) {
			T o = (*_g_array)[_g_current++];

			tempArray->push_back(o);
		};

		return tempArray;
	}
	template<typename T>
	static std::string join(std::deque<T>* a, std::string sep) {
		std::string result = std::string("");
		int _g = 0;
		int _g1 = (int)(a->size());

		while(_g < _g1) {
			int i = _g++;

			if(i > 0) {
				result += sep;
			};

			result += Std::string((*a)[i]);
		};

		return result;
	}
	template<typename T>
	static std::shared_ptr<std::deque<T>> slice(std::deque<T>* a, int pos, std::optional<int> end = std::nullopt) {
		if(pos < 0) {
			pos += (int)(a->size());
		};
		if((pos < 0) || (pos >= (int)(a->size()))) {
			return std::make_shared<std::deque<T>>(std::deque<T>{});
		};
		if((!end.has_value()) || (end.value() > (int)(a->size()))) {
			end = (int)(a->size());
		} else {
			if(end.value() < 0) {
				end.value() += (int)(a->size());
			};
			if(end.value() <= pos) {
				return std::make_shared<std::deque<T>>(std::deque<T>{});
			};
		};

		std::shared_ptr<std::deque<T>> result = std::make_shared<std::deque<T>>();
		int _g = pos;
		std::optional<int> _g1 = end;

		while(_g < _g1.value()) {
			int i = _g++;

			if((i >= 0) && (i < (int)(a->size()))) {
				result->push_back((*a)[i]);
			};
		};

		return result;
	}
	template<typename T>
	static std::shared_ptr<std::deque<T>> splice(std::deque<T>* a, int pos, int len) {
		if(pos < 0) {
			pos += (int)(a->size());
		};
		if((pos < 0) || (pos > (int)(a->size()))) {
			return std::make_shared<std::deque<T>>(std::deque<T>{});
		};
		if(len < 0) {
			return std::make_shared<std::deque<T>>(std::deque<T>{});
		};
		if(pos + len > (int)(a->size())) {
			len = (int)(a->size() - pos);
		};

		auto beginIt = a->begin();
		auto startIt = beginIt + pos;
		auto endIt = beginIt + pos + len;
		std::shared_ptr<std::deque<T>> result = std::make_shared<std::deque<T>>();
		int _g = pos;
		int _g1 = pos + len;

		while(_g < _g1) {
			int i = _g++;

			if((i >= 0) && (i < (int)(a->size()))) {
				result->push_back((*a)[i]);
			};
		};

		a->erase(startIt, endIt);

		return result;
	}
	template<typename T>
	static void insert(std::deque<T>* a, int pos, T x) {
		if(pos < 0) {
			auto it = a->end() + pos + 1;

			a->insert(it, x);
		} else {
			auto it = a->begin() + pos;

			a->insert(it, x);
		};
	}
	template<typename T>
	static int indexOf(std::deque<T>* a, T x, int fromIndex = 0) {
		auto it = std::find(a->begin(), a->end(), x);
		int tempResult = 0;

		if(it != a->end()) {
			tempResult = ((int)(it - a->begin()));
		} else {
			tempResult = -1;
		};

		return tempResult;
	}
	template<typename T>
	static int lastIndexOf(std::deque<T>* a, T x, int fromIndex = -1) {
		int tempNumber = 0;

		if(fromIndex < 0) {
			tempNumber = 0;
		} else {
			tempNumber = (int)(a->size() - (fromIndex + 1));
		};

		int offset = tempNumber;
		auto it = std::find(a->rbegin() + offset, a->rend(), x);
		int tempResult = 0;

		if(it != a->rend()) {
			tempResult = ((int)(it - a->rbegin()));
		} else {
			tempResult = -1;
		};

		return tempResult;
	}
	template<typename T, typename S>
	static std::shared_ptr<std::deque<S>> map(std::deque<T>* a, std::function<S(T)> f) {
		std::shared_ptr<std::deque<S>> _g = std::make_shared<std::deque<S>>(std::deque<S>{});
		int _g_current = 0;
		std::deque<T>* _g_array = a;

		while(_g_current < (int)(_g_array->size())) {
			T v = (*_g_array)[_g_current++];
			S x = f(v);

			_g->push_back(x);
		};

		return _g;
	}
	template<typename T>
	static std::shared_ptr<std::deque<T>> filter(std::deque<T>* a, std::function<bool(T)> f) {
		std::shared_ptr<std::deque<T>> _g = std::make_shared<std::deque<T>>(std::deque<T>{});
		int _g_current = 0;
		std::deque<T>* _g_array = a;

		while(_g_current < (int)(_g_array->size())) {
			T v = (*_g_array)[_g_current++];

			if(f(v)) {
				_g->push_back(v);
			};
		};

		return _g;
	}
	template<typename T>
	static std::string toString(std::deque<T>* a) {
		std::string result = std::string("[");
		int _g = 0;
		int _g1 = (int)(a->size());

		while(_g < _g1) {
			int i = _g++;
			std::string tempString;

			if(i != 0) {
				tempString = std::string(", ");
			} else {
				tempString = std::string("");
			};

			result += (tempString) + Std::string((*a)[i]);
		};

		return result + std::string("]");
	}
};

