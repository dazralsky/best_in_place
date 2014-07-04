module BestInPlace
  module Helper

    def best_in_place(object, field, opts = {})

      best_in_place_assert_arguments(opts)
      type = opts[:as] || :input
      field = field.to_s

      options={}
      options[:data]= HashWithIndifferentAccess.new(opts[:data])
      options[:data]['bip-type'] = type
      options[:data]['bip-attribute'] = field

      real_object = best_in_place_real_object_for object

      display_value = best_in_place_build_value_for(real_object, field, opts)

      value = real_object.send(field)

      if opts[:collection] or type == :checkbox
        collection = opts[:collection]
        case type
          when :checkbox
            value = value.to_s
            if collection.blank?
              collection = best_in_place_default_collection
            else
              collection = best_in_place_collection_builder(collection)
            end
            display_value = collection[value]
            collection = collection.to_json
          else # :select
            collection = best_in_place_collection_builder(collection)
            display_value = collection[value]
            collection = collection.to_json
        end
        options[:data]['bip-collection'] = html_escape(collection)
      end

      options[:class] = ['best_in_place'] + Array(opts[:class] || opts[:classes])
      options[:id] = opts[:id] || BestInPlace::Utils.build_best_in_place_id(real_object, field)


      options[:data]['bip-activator'] = opts[:activator].presence


      options[:data]['bip-html-attrs'] = opts[:html_attrs].to_json unless opts[:html_attrs].blank?
      options[:data]['bip-inner-class'] = opts[:inner_class].presence

      options[:data]['bip-placeholder'] = html_escape(opts[:place_holder]).presence

      options[:data]['bip-object'] = opts[:param] || BestInPlace::Utils.object_to_key(real_object)
      options[:data]['bip-ok-button'] = opts[:ok_button].presence
      options[:data]['bip-ok-button-class'] = opts[:ok_button_class].presence
      options[:data]['bip-cancel-button'] = opts[:cancel_button].presence
      options[:data]['bip-cancel-button-class'] = opts[:cancel_button_class].presence
      options[:data]['bip-original-content'] = html_escape(value).presence


      options[:data]['bip-url'] = url_for(opts[:url] || object)

      options[:data]['bip-confirm'] = opts[:confirm].presence
      options[:data]['bip-value'] = html_escape(value).presence


      if opts[:sanitize].presence.to_s == 'false'
        options[:data][:sanitize] = false
      end

      #delete nil keys only
      options[:data].delete_if { |k, v| v.nil? }

      content_tag(:span, options) do
        !options[:data][:sanitize] ? display_value : display_value.html_safe
      end

    end

    def best_in_place_if(condition, object, field, opts={})
      if condition
        best_in_place(object, field, opts)
      else
        best_in_place_build_value_for best_in_place_real_object_for(object), field, opts
      end
    end

    def best_in_place_unless(condition, object, field, opts={})
      best_in_place_if(!condition, object, field, opts)
    end


    private

    def best_in_place_build_value_for(object, field, opts)
      klass = object.class

      if opts[:display_as]
        BestInPlace::DisplayMethods.add_model_method(klass, field, opts[:display_as])
        object.send(opts[:display_as]).to_s

      elsif opts[:display_with].try(:is_a?, Proc)
        BestInPlace::DisplayMethods.add_helper_proc(klass, field, opts[:display_with])
        opts[:display_with].call(object.send(field))

      elsif opts[:display_with]
        BestInPlace::DisplayMethods.add_helper_method(klass, field, opts[:display_with], opts[:helper_options])
        if opts[:helper_options]
          BestInPlace::ViewHelpers.send(opts[:display_with], object.send(field), opts[:helper_options])
        else
          field_value = object.send(field)

          if field_value.blank?
            ''
          else
            BestInPlace::ViewHelpers.send(opts[:display_with], field_value)
          end
        end

      else
        object.send(field).to_s
      end
    end

    def best_in_place_real_object_for(object)
      (object.is_a?(Array) && object.last.class.respond_to?(:model_name)) ? object.last : object
    end

    def best_in_place_assert_arguments(args)
      args.assert_valid_keys(:id, :type, :nil, :class, :collection, :data,
                             :activator, :cancel_button, :cancel_button_class, :html_attrs, :inner_class, :nil,
                             :object_name, :ok_button, :ok_button_class, :display_as, :display_with, :path,
                             :use_confirm, :confirm, :sanitize, :helper_options, :url, :place_holder, :class, :as, :param)

      best_in_place_deprecated_options(args)

      if args[:display_as] && args[:display_with]
        fail ArgumentError, 'Can`t use both `display_as`` and `display_with` options at the same time'
      end

      if args[:display_with] && !args[:display_with].is_a?(Proc) && !ViewHelpers.respond_to?(args[:display_with])
        fail ArgumentError, "Can't find helper #{args[:display_with]}"
      end
    end

    def best_in_place_deprecated_options(args)
      if deprecated_option = args.delete(:path)
        args[:url] = deprecated_option
        ActiveSupport::Deprecation.warn('[Best_in_place] :path is deprecated in favor of :url ')
      end

      if deprecated_option = args.delete(:object_name)
        args[:param] = deprecated_option
        ActiveSupport::Deprecation.warn('[Best_in_place] :object_name is deprecated in favor of :param ')
      end

      if deprecated_option = args.delete(:type)
        args[:as] = deprecated_option
        ActiveSupport::Deprecation.warn('[Best_in_place] :type is deprecated in favor of :as ')
      end

      if deprecated_option = args.delete(:classes)
        args[:class] = deprecated_option
        AActiveSupport::Deprecation.warn('[Best_in_place] :classes is deprecated in favor of :class ')
      end

      if deprecated_option = args.delete(:nil)
        args[:place_holder] = deprecated_option
        ActiveSupport::Deprecation.warn('[Best_in_place] :nil is deprecated in favor of :place_holder ')
      end

      if deprecated_option = args.delete(:use_confirm)
        args[:confirm] = deprecated_option
        ActiveSupport::Deprecation.warn('[Best_in_place] :use_confirm is deprecated in favor of :confirm ')
      end

    end

    def best_in_place_collection_builder(collection)
      case collection
        when Array
          Hash[collection.collect { |x| [x.to_s, x.to_s] }]
        else
          collection.stringify_keys
      end
    end

    def best_in_place_default_collection
      {'true' => t(:'best_in_place.yes', default: 'Yes'),
       'false' => t(:'best_in_place.no', default: 'No')}
    end
  end
end



