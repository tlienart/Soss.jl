export Model, convert

struct Model
    args :: Set{Symbol}
    body :: Expr
end

(m::Model)(s) = begin
    result = deepcopy(m)
    push!(result.args, s)
    newbody = postwalk(result.body) do x 
        if @capture(x, v_ ~ dist_) && (v ∈ [s])
            :($v ⩪ $dist)
        else x
        end
    end
    Model(result.args, newbody)
end

(m::Model)(vs...) = begin
    result = deepcopy(m)
    union!(result.args, vs)
    newbody = postwalk(result.body) do x 
        if @capture(x, v_ ~ dist_) && (v ∈ vs)
            :($v ⩪ $dist)
        else x
        end
    end
    Model(result.args, newbody)
end


(m::Model)(;kwargs...) = begin
    result = deepcopy(m)
    setdiff!(result.args, keys(kwargs))
    assignments = [:($k = $v) for (k,v) in kwargs]
    pushfirst!(result.body.args, assignments...)
    newbody = postwalk(result.body) do x 
        if @capture(x, v_ ~ dist_) && v in keys(kwargs)
            :($v ⩪ $dist)
        else x
        end
    end
    Model(result.args, newbody)
end



macro model(vs::Expr,ex)
    Model(Set(vs.args), pretty(ex))
end

macro model(v::Symbol,ex)
    Model(Set([v]), pretty(ex))
end

macro model(ex)   
    Model(Set(),pretty(ex))
end

import Base.convert
convert(Expr, m::Model) = begin
    func = @q function($(m.args),) $(m.body) end
    pretty(func)
end

Base.show(io::IO, m::Model) = begin
    print(io, "@model $(Expr(:tuple, [x for x in m.args]...)) ")
    println(io, m.body)
end
