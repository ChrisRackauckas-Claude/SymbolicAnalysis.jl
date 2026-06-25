using SymbolicAnalysis, Aqua, JET, SciMLTesting

const SA = SymbolicAnalysis

# SymbolicAnalysis's entire purpose is to teach the symbolic-analysis machinery
# about existing functions: it registers DCP/gDCP curvature methods (and the
# Symbolics traversal/symtype/shape hooks they need) on functions owned by Base,
# LinearAlgebra, Symbolics/SymbolicUtils, Manifolds and LogExpFunctions. Those are
# intentional, by-design extensions of non-owned functions, so they are declared to
# Aqua's piracy check via `treat_as_own`. This is the only Aqua exception the
# package needs; ambiguities, stale-deps, etc. all pass cleanly.
const SYMBOLIC_OWN = Any[
    Base.:*, Base.log, Base.sqrt,
    SA.LinearAlgebra.inv, SA.LinearAlgebra.logdet,
    SA.Symbolics.arguments, SA.Symbolics.hasmetadata, SA.Symbolics.promote_symtype,
    SA.SymbolicUtils.promote_shape,
    SA.Manifolds.distance, SA.LogExpFunctions.xlogx,
]

run_qa(
    SymbolicAnalysis;
    explicit_imports = true,
    jet = true,
    aqua_kwargs = (; piracies = (; treat_as_own = SYMBOLIC_OWN)),
    jet_kwargs = (; target_modules = (SymbolicAnalysis,), mode = :typo),
    ei_kwargs = (
        # `issym`/`unwrap` are SymbolicUtils/TermInterface names re-exported through
        # Symbolics; they resolve to a non-owner module and are not (yet) declared
        # public there. These go public as the symbolic base libs add `public`.
        all_explicit_imports_via_owners = (; ignore = (:issym, :unwrap)),
        # `inv`/`sqrt` are owned by Base but accessed via LinearAlgebra (we register
        # methods on `LinearAlgebra.inv`/`LinearAlgebra.sqrt`); `shape`/`unwrap` are
        # SymbolicUtils/TermInterface names accessed via Symbolics.
        all_qualified_accesses_via_owners = (; ignore = (:inv, :sqrt, :shape, :unwrap)),
        all_qualified_accesses_are_public = (;
            ignore = (
                # Symbolics internals (not declared public).
                :Arr, :shape, :unwrap, :wrap, :value,
                # SymbolicUtils internals (not declared public).
                :Chain, :Postwalk, :Prewalk, :ShapeVecT, :_throw_array,
                :inspect_metadata, :promote_shape, :symtype,
                # Base / LinearAlgebra internals.
                :OneTo, :literal_pow, :inv, :sqrt,
            ),
        ),
        # `BasicSymbolic` is SymbolicUtils' core symbolic type; `issym`/`unwrap` are
        # Symbolics' re-exports of SymbolicUtils/TermInterface names. None are public.
        all_explicit_imports_are_public = (; ignore = (:BasicSymbolic, :issym, :unwrap)),
    ),
    # The whole package is built on the symbolic DSL: dozens of names come in via
    # `using Symbolics`/`SymbolicUtils`/`Manifolds`/`DomainSets`/... Making them all
    # explicit is a large, risky refactor tracked separately; keep it @test_broken
    # so the lane stays green while the finding stands.
    ei_broken = (:no_implicit_imports,),  # tracked in SciML/SymbolicAnalysis.jl#114
)
