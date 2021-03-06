__precompile__()
module Holomorphic
    using Base, ApproxFun, SingularIntegralEquations


import ApproxFun: UnivariateSpace, domain, evaluate, ComplexBasis, spacescompatible,
                    Space, defaultFun, union_rule, ConstantSpace, points, checkpoints,
                    transform, plan_transform, conversion_rule, coefficients
import SingularIntegralEquations: stieltjes


export ℂ

# represents the whole Planess
immutable ComplexPlane <: Domain{Complex128,2} end

const ℂ=ComplexPlane()
Base.reverse(C::ComplexPlane)=C

Base.intersect(a::ComplexPlane,b::ComplexPlane)=a
Base.union(a::ComplexPlane,b::ComplexPlane)=a


# represents S\A
immutable Complement{SS,AA,T,d} <: Domain{T,d}
    full::SS
    del::AA
end

Base.intersect(a::Complement,b::Complement)=Complement(a.full ∩ b.full,a.del ∪ b.del)
Base.union(a::Complement,b::Complement)=Complement(a.full ∪ b.full,a.del ∩ b.del)

Complement(A::Domain,B::Domain)=Complement{typeof(A),typeof(B),eltype(A),ndims(A)}(A,B)
Base.setdiff(a::Domain,b::Domain)=Complement(a,b)
Base.reverse(a::Complement)=reverse(a.full)\reverse(a.del)

immutable StieltjesSpace{S,DD} <:  Space{ComplexBasis,Complement{ComplexPlane,DD},2}
    space::S
    function StieltjesSpace(sp::S)
        @assert isa(domain(sp),DD)
        new(sp)
    end
end

StieltjesSpace(sp::UnivariateSpace)=StieltjesSpace{typeof(sp),typeof(domain(sp))}(sp)
spacescompatible(a::StieltjesSpace,b::StieltjesSpace)=spacescompatible(a.space,b.space)

domain(sp::StieltjesSpace)=ℂ\domain(sp.space)
evaluate(v::AbstractVector,sp::StieltjesSpace,z)=stieltjes(sp.space,v,z)
stieltjes(f::Fun)=Fun(f.coefficients,StieltjesSpace(space(f)))

union_rule(A::StieltjesSpace,B::StieltjesSpace)=StieltjesSpace(A.space ∪ B.space)
coefficients(v::Vector,A::StieltjesSpace,B::StieltjesSpace)=coefficients(v,A.space,B.space)


# construct spaces for complement
# we assume boundedness

Space{DD<:Interval}(Γ::Complement{ComplexPlane,DD})=StieltjesSpace(JacobiWeight(0.5,0.5,Ultraspherical{1}(Γ.del)))
Space{DD<:Circle}(Γ::Complement{ComplexPlane,DD})=StieltjesSpace(Laurent(Γ.del))
Space{DD<:UnionDomain}(Γ::Complement{ComplexPlane,DD})=StieltjesSpace(PiecewiseSpace(map(d->Space(d).space,map(x->ComplexPlane()\x,Γ.del))))



## Interval

checkpoints{DD<:Interval}(C::Complement{ComplexPlane,DD})=[fromcanonical(C.del,1im),fromcanonical(C.del,2.)]

joukowsky(z)=(z+1./z)./2

points{DD<:Interval}(S::StieltjesSpace{JacobiWeight{Ultraspherical{1,DD},DD},DD},n)=
    fromcanonical(domain(S).del,joukowsky(points((1-1/n)*Circle(),n)))

plan_transform{DD<:Interval}(S::StieltjesSpace{JacobiWeight{Ultraspherical{1,DD},DD},DD},vals::Vector)=
        plan_transform(Taylor((1-1/length(vals))*Circle()),vals)

function transform{DD<:Interval}(S::StieltjesSpace{JacobiWeight{Ultraspherical{1,DD},DD},DD},vals,plan)
    @assert S.space.α==S.space.β==0.5
    n=length(vals)
    L=Laurent((1-1/n)*Circle())
    cfs1=transform(L,vals)
    for k=3:2:length(cfs1)
        cfs1[k]*=1/((1-1/n)^(div(k+1,2)-1)*π)
    end
    for k=2:2:length(cfs1)
        cfs1[k]*=(1-1/n)^(div(k,2))/(π)
    end

    L=Laurent(1/(1-1/n)*Circle())
    vals2=[vals[1];reverse!(vals[2:end])]
    cfs2=transform(L,vals2)

    for k=3:2:length(cfs2)
        cfs2[k]*=(1-1/n)^(div(k+1,2)-1)/(π)
    end
    for k=2:2:length(cfs2)
        cfs2[k]*=1/((1-1/n)^(div(k,2))*π)
    end
    (cfs1-cfs2)[3:2:end]
end


# function transform{DD<:Interval}(S::StieltjesSpace{JacobiWeight{Ultraspherical{1,DD},DD},DD},vals,plan)
#     @assert S.space.α==S.space.β==0.5
#     n=length(vals)
#     cfs=transform(Taylor((1-1/n)*Circle()),vals,plan)
#     for k=2:length(cfs)
#         cfs[k]*=1/((1-1/n)^(k-1)*π)
#     end
#     cfs
# end



## ℂ\Circle()





# represents strip between a < ℑ(z*exp(-im*θ)) < b
immutable Strip{T} <: Domain{Complex{T},2}
    a::T
    b::T
    θ::T
end

Strip(a,b,θ) = Strip(promote(a,b,θ)...)
Strip(a,b) = Strip(a,b,0)
Strip(b) = Strip(-b,b)

Base.show(io::IO,d::ComplexPlane)=print(io,"ℂ")
Base.show(io::IO,d::Complement)=print(io,"$(d.full) \\$(d.del)")



end #module




