# Allows compound expectations such as
#   expect { ... }.to change(A, :count).by(-1).and not_change(B, :count)
RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_job, :have_enqueued_job
RSpec::Matchers.define_negated_matcher :not_include, :include
