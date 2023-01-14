#pragma once

#define TEGO_STRINGIFY_IMPL(X) #X
#define TEGO_STRINGIFY(X) TEGO_STRINGIFY_IMPL(X)

#define TEGO_THROW_MSG(FMT, ...) throw std::runtime_error(fmt::format("runtime error " __FILE__ ":" TEGO_STRINGIFY(__LINE__) " " FMT __VA_OPT__(,) __VA_ARGS__));

#define TEGO_THROW_IF_FALSE_MSG(B, ...) if (!(B)) { TEGO_THROW_MSG(__VA_ARGS__); }
#define TEGO_THROW_IF_FALSE(B) TEGO_THROW_IF_FALSE_MSG(B, "{} must be true", TEGO_STRINGIFY(B))

#define TEGO_THROW_IF_TRUE_MSG(B, ...) if (B) { TEGO_THROW_MSG("{}", __VA_ARGS__); }
#define TEGO_THROW_IF_TRUE(B) TEGO_THROW_IF_TRUE_MSG(B, "{} must be false", TEGO_STRINGIFY(B))
#define TEGO_THROW_IF TEGO_THROW_IF_TRUE

#define TEGO_THROW_IF_NULL(PTR) TEGO_THROW_IF_FALSE_MSG((PTR != nullptr), "{} must not be null", TEGO_STRINGIFY(PTR))
#define TEGO_THROW_IF_NOT_NULL(PTR) TEGO_THROW_IF_FALSE_MSG((PTR == nullptr), "{} must be null", TEGO_STRINGIFY(PTR))

#define TEGO_THROW_IF_EQUAL(A, B) if((A) == (B)) { TEGO_THROW_MSG("{} and {} must not be equal", TEGO_STRINGIFY(A), TEGO_STRINGIFY(B)); }

namespace tego
{
    //
    // call functor at end of scope
    //
    template<typename T>
    class scope_exit
    {
    public:
        scope_exit() = delete;
        scope_exit(const scope_exit&) = delete;
        scope_exit& operator=(const scope_exit&) = delete;
        scope_exit& operator=(scope_exit&&) =  delete;

        scope_exit(scope_exit&&) = default;
        scope_exit(T&& functor)
         : functor_(new T(std::move(functor)))
        {
            static_assert(std::is_same<void, decltype(functor())>::value);
        }

        ~scope_exit()
        {
            if (functor_.get())
            {
                functor_->operator()();
            }
        }

    private:
        std::unique_ptr<T> functor_;
    };


    template<typename FUNC>
    auto make_scope_exit(FUNC&& func) ->
        scope_exit<typename std::remove_reference<decltype(func)>::type>
    {
        return {std::move(func)};
    }

    //
    // constexpr strlen for compile-time null terminated C String constants
    //
    template<size_t N>
    constexpr size_t static_strlen(const char (&str)[N])
    {
        if (str[N-1] != 0) throw "C String missing null terminator";
        for(size_t i = 0; i < (N - 1); i++)
        {
            if (str[i] == 0) throw "C String has early null terminator";
        }
        return N-1;
    }

    //
    // helper class for populating out T** params into unique_ptr<T> objects
    //
    template<typename T>
    class out_unique_ptr
    {
    public:
        out_unique_ptr() = delete;
        out_unique_ptr(const out_unique_ptr&) = delete;
        out_unique_ptr(out_unique_ptr&&) = delete;
        out_unique_ptr& operator=(const out_unique_ptr&) = delete;
        out_unique_ptr& operator=(out_unique_ptr&&) = delete;

        out_unique_ptr(std::unique_ptr<T>& u) : u_(u) {}
        ~out_unique_ptr()
        {
            u_.reset(t_);
        }

        operator T**()
        {
            return &t_;
        }

    private:
        T* t_ = nullptr;
        std::unique_ptr<T>& u_;
    };

    //
    // helper function for populating out T** params
    // example:
    //
    // void give_int(int** outInt);
    // std::unique_ptr<int> pint;
    // give_int(tego::out(pint));
    // int val = *pint;
    //
    template<typename T>
    out_unique_ptr<T> out(std::unique_ptr<T>& ptr)
    {
        return {ptr};
    }
}
