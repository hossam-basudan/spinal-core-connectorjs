# Copyright 2015 SpinalCom - www.spinalcom.com
#
# This file is part of SpinalCore.
#
# Please read all of the following terms and conditions
# of the Free Software license Agreement ("Agreement")
# carefully.
#
# This Agreement is a legally binding contract between
# the Licensee (as defined below) and SpinalCom that
# sets forth the terms and conditions that govern your
# use of the Program. By installing and/or using the
# Program, you agree to abide by all the terms and
# conditions stated or referenced herein.
#
# If you do not agree to abide by these terms and
# conditions, do not demonstrate your acceptance and do
# not install or use the Program.
#
# You should have received a copy of the license along
# with this file. If not, see
# <http://resources.spinalcom.com/licenses.pdf>.


# vector of objects inherited from Model
root = if typeof _root_obj == "undefined" then global else window

class root.Lst extends Model
    constructor: ( data ) ->
        super()
        
        # default
        @length = 0
        
        # static length case
        s = @static_length()
        if s >= 0
            d = @default_value()
            for i in [ 0 ... s ]
                @push d, true
        
        # init
        if data?
            @_set data

    # if static_length < 0, length is dynamic (push, pop, ... are allowed)
    # else, length = static_length
    # may be redefined
    static_length: ->
        -1
    
    # used for initialisation of for resize
    # may be redefined
    default_value: ->
        0

    # if base_type is defined, all values must be of this type
    base_type: ->
        undefined

    get: ->
        for i in this
            i.get()

    # tensorial size (see models)
    size: ->
        [ length ]
    
    toString: ->
        if @length
            l = for x in this
                x.toString()
            l.join()
        else
            ""

    equals: ( lst ) ->
        if @length != lst.length
            return false
        for i in [ 0 ... @length ]
            if not this[ i ].equals( lst[ i ] )
                return false
        return true
        
    
    # append value at the end of the list
    push: ( value, force = false ) ->
        if @_static_size_check force
            return
        
        b = @base_type()
        if b?
            if value not instanceof b
                value = new b value
        else
            value = ModelProcessManager.conv value
        
        
        if this not in value._parents
            value._parents.push this
            
        @[ @length ] = value
        @length += 1
        
        @_signal_change()

    # remove and return the last element
    pop: ->
        if @_static_size_check false
            return
        if @length <= 0
            return
        @length -= 1
        old = this[ @length ]
        @rem_attr @length
        return old

    #
    clear: ->
        while @length
            @pop()
    
    # add an element to the beginning of an array, return the new length
    unshift: ( element ) ->
        if @_static_size_check false
            return
            
        b = @base_type()
        if b?
            if element not instanceof b
                element = new b element
        else
            element = ModelProcessManager.conv element
        if this not in element._parents
            element._parents.push this
 
        if @length
            for i in [ @length - 1 .. 0 ]
                @[ i + 1 ] = @[ i ]
            
        @[ 0 ] = element
        @length += 1
        
        @_signal_change()
        return @length
        
        
    # remove and return the first element
    shift: ->
        r = this[ 0 ]
        @splice 0, 1
        return r

    # remove item from the list id present
    remove: ( item ) ->
        i = @indexOf item
        if i >= 0
            @splice i, 1
            
    # remove item from the list id present, based on ref comparison
    remove_ref: ( item ) ->
        i = @indexOf_ref item
        if i >= 0
            @splice i, 1

    # return a list with item such as f( item ) is true
    filter: ( f ) ->
        for i in this when f i
            i
            
    # return the first item such as f( item ) is true. If not item, return undefined
    detect: ( f ) ->
        for i in this
            if f i
                return i
        return undefined

    # sort item depending function and return a new Array
    sorted: ( fun_sort ) ->
        # lst to array
        new_array = new Array
        for it in this
            new_array.push it
            
        #sort array
        new_array.sort fun_sort
        
        return new_array

    # return true if there is an item that checks f( item )
    has: ( f ) ->
        for i in this
            if f i
                return true
        return false

    # returns index of v if v is present in the list. Else, return -1
    indexOf: ( v ) ->
        for i in [ 0 ... @length ]
            if @[ i ].equals v
                return i
        return -1

    # returns index of v if v is present in the list, based on ref comparison. Else, return -1
    indexOf_ref: ( v ) ->
        for i in [ 0 ... @length ]
            if @[ i ] == v
                return i
        return -1

    contains: ( v ) ->
        @indexOf( v ) >= 0

    contains_ref: ( v ) ->
        @indexOf_ref( v ) >= 0

    # toggle presence of v. return true if added
    toggle: ( v ) ->
        i = @indexOf v
        if i >= 0
            @splice i
            false
        else
            @push v
            true

    # toggle presence of v, base on ref comparison
    toggle_ref: ( v ) ->
        i = @indexOf_ref v
        if i >= 0
            @splice i
            false
        else
            @push v
            true

    #return a new lst between begin and end index
    slice: ( begin, end = this.length ) ->
        if begin < 0
            begin = 0
        if end > this.length
            end = this.length
        tab = new Lst
        for i in [ begin ... end ]
            tab.push @[ i ].get()
        return tab
        
    #return list with new_tab after
    concat: ( new_tab, force = false ) ->
        if @_static_size_check force
            return
        if new_tab.length
            for el in new_tab
                this.push el
            return this
        
    # remove n items from index
    splice: ( index, n = 1 ) ->
        if @_static_size_check false
            return

        for i in [ index ... Math.min( index + n, @length ) ]
            @rem_attr i
        for i in [ index ... @length - n ]
            @[ i ] = @[ i + n ]
        for i in [ @length - n ... @length ]
            delete @[ i ]
        @length -= n
        
        @_signal_change()

    # remove n items before index
    insert: ( index, list ) ->
        if list.length
            l = Math.max @length - index, 0
            o = for i in [ 0 ... l ]
                @pop()
            o.reverse()
            for l in list
                @push l
            for l in o
                @push l
    
    # permits to set an item or to grow the list if index == @length
    set_or_push: ( index, val ) ->
        if index < @length
            @mod_attr index, val
        else if index == @length
            @push val
    
    # permits to reduce the size (resize is allowed only if we known how to create new items)
    trim: ( size ) ->
        while @length > size
            @pop()
    
    # return a string with representation of items, separated by sep
    join: ( sep ) ->
        @get().join sep

    #
    deep_copy: ->
        res = new Lst
        for i in [ 0 ... @length ]
            res.push this[ i ].deep_copy()
        res

    # last element
    back: ->
        @[ @length - 1 ]
        
    # returns true if change is not "cosmetic"
    real_change: ->
        if @has_been_directly_modified()
            return true
        for a in this
            if a.real_change()
                return true
        return false
        
    #
    _set: ( value ) ->
        change = @length != value.length
        
        s = @static_length()
        if s >= 0 and change
            console.error "resizing a static array (type " +
             "#{ModelProcessManager.get_object_class this}) is forbidden"
            
        for p in [ 0 ... value.length ]
            if p < @length
                change |= @[ p ].set value[ p ]
            else if s < 0
                @push value[ p ]

        if s < 0
            while @length > value.length
                @pop()

            @length = value.length

        return change

    _get_flat_model_map: ( map, date ) ->
        map[ @model_id ] = this
        
        for obj in this
            if not map[ obj.model_id ]?
                if obj._date_last_modification > date
                    obj._get_flat_model_map map, date

    _get_fs_data: ( out ) ->
        FileSystem.set_server_id_if_necessary out, this
        str = for obj in this
            FileSystem.set_server_id_if_necessary out, obj
            obj._server_id
        out.mod += "C #{@_server_id} #{str.join ","} "

    _get_state: ->
        str = for obj in this
            obj.model_id
        return str.join ","
        
    _set_state: ( str, map ) ->
        l_id = str.split( "," ).filter ( x ) -> x.length
        while @length > l_id.length
            @pop()
        
        for attr in [ 0 ... @length ]
            k_id = l_id[ attr ]
#             if not map[ k_id ]?
#                 console.log map, k_id
            if map[ k_id ].buff?
                if map[ k_id ].buff != this[ attr ]
                    @mod_attr attr, map[ k_id ].buff
            else if not this[ attr ]._set_state_if_same_type k_id, map
                @mod_attr attr, ModelProcessManager._new_model_from_state k_id, map

        for attr in [ @length ... l_id.length ]
            k_id = l_id[ attr ]
            if map[ k_id ].buff?
                @push map[ k_id ].buff
            else
                @push ModelProcessManager._new_model_from_state k_id, map

    _static_size_check: ( force ) ->
        if @static_length() >= 0 and not force
            console.error "resizing a static array (type " +
             "#{ModelProcessManager.get_object_class this}) is forbidden"
            return true
        return false
