require 'spec_helper'

module Ransack
  module Helpers
    describe FormBuilder do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people
        match ':controller(/:action(/:id(.:format)))'
      end

      include router.url_helpers

      # FIXME: figure out a cleaner way to get this behavior
      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval do
          include router.url_helpers
        end

        @controller.view_context_class.class_eval do
          include router.url_helpers
        end

        @s = Person.search
        @controller.view_context.search_form_for @s do |f|
          @f = f
        end
      end

      it 'selects previously-entered time values with datetime_select' do
        @s.created_at_eq = [2011, 1, 2, 3, 4, 5]
        html = @f.datetime_select :created_at_eq, :use_month_numbers => true, :include_seconds => true
        %w(2011 1 2 03 04 05).each do |val|
          html.should match /<option selected="selected" value="#{val}">#{val}<\/option>/
        end
      end

      describe '#label' do

        it 'localizes attribute names' do
          html = @f.label :name_cont
          html.should match /Full Name contains/
        end

      end

      describe '#sort_link' do
        subject { @f.sort_link :name, :controller => 'people' }

        it { should match /people\?q%5Bs%5D=name\+asc/}
        it { should match /sort_link/}
        it { should match /Full Name<\/a>/}
      end

      describe '#submit' do

        it 'localizes :search when no default value given' do
          html = @f.submit
          html.should match /"Search"/
        end

      end

      describe '#attribute_select' do

        it 'returns ransackable attributes' do
          html = @f.attribute_select
          html.split(/\n/).should have(Person.ransackable_attributes.size + 1).lines
          Person.ransackable_attributes.each do |attribute|
            html.should match /<option value="#{attribute}">/
          end
        end

        it 'returns only ransackable attributes given in :only' do
          html = @f.attribute_select :only => ['name']
          html.split(/\n/).should have(2).lines
          html.should match /<option value="name">/
        end

        it 'returns only ransackable attributes for associations with :associations given in :only' do
          html = @f.attribute_select :associations => ['articles'], :only => ['name', 'title']
          html.split(/\n/).should have(2).lines
          ['name', 'articles_title'].each do |attribute|
            html.should match /<option value="#{attribute}">/
          end
        end
        
        it 'returns ransackable attributes for associations with :associations' do
          attributes = Person.ransackable_attributes + Article.ransackable_attributes.map {|a| "articles_#{a}"}
          html = @f.attribute_select :associations => ['articles']
          html.split(/\n/).should have(attributes.size).lines
          attributes.each do |attribute|
            html.should match /<option value="#{attribute}">/
          end
        end


        it 'returns option groups for base and associations with :associations' do
          html = @f.attribute_select :associations => ['articles']
          [Person, Article].each do |model|
            html.should match /<optgroup label="#{model}">/
          end
        end

      end

      describe '#condition_fields' do
        it 'returns previously-entered values' do
          @s.name_eq = "basilikum"
          html = ''
          @f.condition_fields do |c|
            c.attribute_fields do |a|
              html = a.attribute_select
            end
          end
          html.should match /<option value=\"name\" selected/
        end
        
        it 'filters attributes in :except' do
          @s.name_eq = "basilikum"
          html = ''
          @f.condition_fields :except => ['name'] do |c|
            c.attribute_fields do |a|
              html = a.attribute_select
            end
          end
          html.should_not match /<option value=\"name\" selected/
        end
      end

      describe '#predicate_select' do

        it 'returns predicates with predicate_select' do
          html = @f.predicate_select
          Predicate.names.each do |key|
            html.should match /<option value="#{key}">/
          end
        end

        it 'filters predicates with single-value :only' do
          html = @f.predicate_select :only => 'eq'
          Predicate.names.reject {|k| k =~ /^eq/}.each do |key|
            html.should_not match /<option value="#{key}">/
          end
        end

        it 'filters predicates with multi-value :only' do
          html = @f.predicate_select :only => [:eq, :lt]
          Predicate.names.reject {|k| k =~ /^(eq|lt)/}.each do |key|
            html.should_not match /<option value="#{key}">/
          end
        end

        it 'excludes compounds when :compounds => false' do
          html = @f.predicate_select :compounds => false
          Predicate.names.select {|k| k =~ /_(any|all)$/}.each do |key|
            html.should_not match /<option value="#{key}">/
          end
        end
      end
    end
  end
end
