require 'typelib/test'

describe Typelib::ContainerType do
    attr_reader :registry
    before do
        @registry = Typelib::CXXRegistry.new
    end

    let(:element_t) { registry.get('/int32_t') }
    let(:value_t) { registry.create_container '/std/vector', element_t }

    describe "the type model" do
        describe "#to_h" do
            attr_reader :container_t, :element_t
            before do
                @container_t = registry.create_container '/std/vector', '/int32_t'
                @element_t = container_t.deference
            end

            it "should be able to describe the type" do
                expected = Hash[class: 'Typelib::ContainerType',
                                name: container_t.name,
                                element: element_t.to_h_minimal(layout_info: false)]
                assert_equal expected, container_t.to_h(layout_info: false, recursive: false)
            end

            it "should describe the sub-type fully if recursive is true" do
                expected = Hash[class: 'Typelib::ContainerType',
                                name: container_t.name,
                                element: element_t.to_h(layout_info: false)]
                assert_equal expected, container_t.to_h(layout_info: false, recursive: true)
            end
        end
    end

    describe "__element_from_ruby" do
        it "does not unnecessarily converts numeric values from ruby" do
            flexmock(Typelib).should_receive(:from_ruby).never
            value = value_t.new
            value.__element_from_ruby(0)
        end
        it "converts values from ruby if needed" do
            ruby_t = Class.new
            el = element_t.new
            element_t.convert_from_ruby(ruby_t) { |v, t| el }
            value = value_t.new
            assert_same el, value.__element_from_ruby(ruby_t.new)
        end
    end

    describe "#<<" do
        it "should accept being chained" do
            value = value_t.new
            value << 0 << 1
            assert_equal 2, value.size
            assert_equal [0, 1], value.to_a
        end
    end

    describe "#to_simple_value" do
        attr_reader :ruby_value, :value
        before do
            value_t = registry.create_container '/std/vector', '/int32_t'
            @ruby_value = (1..10).to_a
            @value = Typelib.from_ruby(ruby_value, value_t)
        end

        it "returns the corresponding plain ruby value if :pack_simple_arrays is false" do
            v = value.to_simple_value(pack_simple_arrays: false)
            assert_equal ruby_value, v
        end
        it "returns the pack code as well as the packed data if :pack_simple_arrays is true and the array elements are numerics" do
            v = value.to_simple_value(pack_simple_arrays: true)
            assert_equal ruby_value, Base64.strict_decode64(v[:data]).unpack("#{v[:pack_code]}*")
        end
    end
end

