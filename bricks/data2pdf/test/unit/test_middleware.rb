require 'helper'

class TestMiddleware < Test::Unit::TestCase

  context 'A Middleware instance' do
    subject do
      Data2pdf::Middleware.new(lambda{|env| [200, {}, [""] ]})
    end

    should 'be initialized with another Middleware' do
      assert subject.instance_variable_get(:@app).respond_to?(:call, {})
    end

    should 'respond to call with one argument exactly' do
      assert subject.respond_to?(:call, {})
      assert_raise(ArgumentError){ subject.respond_to?(:call, {}, {}) }
    end

    context 'has a #call method that' do

      should 'return an instance of an array with 3 values' do
        assert subject.call({}).is_a?(Array)
        assert_equal 3, subject.call({}).size
      end

    end # has a #call method that

  end # A Middleware instance

  context 'Initialisation options' do
    setup do
      @app = lambda{|env| [200, {}, [""] ]}
    end

    should 'accept valid engine' do
      assert Data2pdf::Middleware.new(@app, :engine => 'Xhtml2pdf')
    end

    should 'accept css file' do
      subject =  Data2pdf::Middleware.new(@app, :css => '../fixtures/applications.css')
      assert_match /application/, subject.instance_variable_get(:@css)
    end

  end # Initialisation options


end
