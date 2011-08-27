module Watir

  # This class is used for dealing with tables.
  # Normally a user would not need to create this object as it is returned by the Watir::Container#table method
  #
  # many of the methods available to this object are inherited from the Element class
  #
  class Table < Element
    include Container

    # Returns the table object containing the element
    #   * container  - an instance of an IE object
    #   * anElement  - a Watir object (TextField, Button, etc.)
    def Table.create_from_element(container, element)
      element.locate if element.respond_to?(:locate)
      o = element.ole_object.parentElement
      o = o.parentElement until o.tagName == 'TABLE'
      new container, :ole_object, o 
    end
    
    # Returns an initialized instance of a table object
    #   * container      - the container
    #   * how         - symbol - how we access the table
    #   * what         - what we use to access the table - id, name index etc
    def initialize(container, how, what)
      set_container container
      @how = how
      @what = what
      super nil
    end
    
    # override the highlight method, as if the tables rows are set to have a background color,
    # this will override the table background color, and the normal flash method won't work
    def highlight(set_or_clear)
      if set_or_clear == :set
        begin
          @original_border = @o.border.to_i
          if @o.border.to_i==1
            @o.border = 2
          else
            @o.border = 1
          end
        rescue
          @original_border = nil
        end
      else
        begin
          @o.border= @original_border unless @original_border == nil
          @original_border = nil
        rescue
          # we could be here for a number of reasons...
        ensure
          @original_border = nil
        end
      end
      super
    end
    
    # this method is used to populate the properties in the to_s method
    def table_string_creator
      n = []
      n << "rows:".ljust(TO_S_SIZE) + self.row_count.to_s
      n << "cols:".ljust(TO_S_SIZE) + self.column_count.to_s
      return n
    end
    private :table_string_creator
    
    # returns the properties of the object in a string
    # raises an ObjectNotFound exception if the object cannot be found
    def to_s
      assert_exists
      r = string_creator
      r += table_string_creator
      return r.join("\n")
    end
    
    # iterates through the rows in the table. Yields a TableRow object
    def each
      assert_exists
      0.upto(@o.rows.length - 1) do |i| 
        yield TableRow.new(@container, :ole_object, _row(i))
      end
    end
    
    # Returns a row in the table
    #   * index         - the index of the row
    def [](index)
      assert_exists
      return TableRow.new(@container, :ole_object, _row(index))
    end
    
    # Returns the number of rows inside the table, including rows in nested tables.
    def row_count
      assert_exists
      #return table_body.children.length
      return @o.getElementsByTagName("TR").length
    end

    # Returns the number of rows in the table, not including rows in nested tables.    
    def row_count_excluding_nested_tables
      assert_exists
      return @o.rows.length
    end    
    
    # This method returns the number of columns in a row of the table.
    # Raises an UnknownObjectException if the table doesn't exist.
    #   * index         - the index of the row
    def column_count(index=0)
      assert_exists
      _row(index).cells.length
    end
    
    # Returns multi-dimensional array of the cell texts in a table.
    #
    # Works with tr, th, td elements, colspan, rowspan and nested tables.
    # Takes an optional parameter *max_depth*, which is by default 1
    def to_a(max_depth=1)
      assert_exists
      y = []
      @o.rows.each do |row|
        y << TableRow.new(@container, :ole_object, row).to_a(max_depth)
      end
      y
    end
    
    def table_body(index=0)
      return @o.getElementsByTagName('TBODY')[index]
    end
    private :table_body
    
    # returns a watir object
    def body(how, what)
      return TableBody.new(@container, how, what, self)
    end
    
    # returns a watir object
    def bodies
      assert_exists
      return TableBodies.new(@container, @o)
    end
    
    # returns an ole object
    def _row(index)
      return @o.invoke("rows").item(index)
    end
    private :_row
    
    # Returns an array containing all the text values in the specified column
    # Raises an UnknownCellException if the specified column does not exist in every
    # Raises an UnknownObjectException if the table doesn't exist.
    # row of the table
    #   * columnnumber  - column index to extract values from
    def column_values(columnnumber)
      return (0..row_count - 1).collect {|i| self[i][columnnumber].text}
    end
    
    # Returns an array containing all the text values in the specified row
    # Raises an UnknownObjectException if the table doesn't exist.
    #   * rownumber  - row index to extract values from
    def row_values(rownumber)
      return (0..column_count(rownumber) - 1).collect {|i| self[rownumber][i].text}
    end
    
  end
  
  # this class is a collection of the table body objects that exist in the table
  # it wouldnt normally be created by a user, but gets returned by the bodies method of the Table object
  # many of the methods available to this object are inherited from the Element class
  #
  class TableBodies < Element
    def initialize(container, parent_table)
      set_container container
      @o = parent_table     # in this case, @o is the parent table
    end
    
    # returns the number of TableBodies that exist in the table
    def length
      assert_exists
      return @o.tBodies.length
    end
    
    # returns the n'th Body as a Watir TableBody object
    def []n
      assert_exists
      return TableBody.new(@container, :ole_object, ole_table_body_at_index(n))
    end
    
    # returns an ole table body
    def ole_table_body_at_index(n)
      return @o.tBodies.item(n)
    end
    
    # iterates through each of the TableBodies in the Table. Yields a TableBody object
    def each
      0.upto(@o.tBodies.length - 1) do |i| 
        yield TableBody.new(@container, :ole_object, ole_table_body_at_index(i))
      end
    end
    
  end
  
  # this class is a table body
  class TableBody < Element
    def locate
      @o = nil
      if @how == :ole_object
        @o = @what     # in this case, @o is the table body
      elsif @how == :index
        @o = @parent_table.bodies.ole_table_body_at_index(@what)
      end
      @rows = []
      if @o
        @o.rows.each do |oo|
          @rows << TableRow.new(@container, :ole_object, oo)
        end
      end
    end
    
    def initialize(container, how, what, parent_table=nil)
      set_container container
      @how = how
      @what = what
      @parent_table = parent_table
      super nil
    end
    
    # returns the specified row as a TableRow object
    def [](n)
      assert_exists
      return @rows[n]
    end
    
    # iterates through all the rows in the table body
    def each
      locate
      0.upto(length - 1) { |i| yield @rows[i] }
    end
    
    # returns the number of rows in this table body.
    def length
      return @rows.length
    end
  end
    
  class TableRow < Element
    TAG = "TR"
    
    def locate
      super
      cells if @o
    end

    def cells
      return @cells if @cells

      @cells = []
      @o.cells.each do |c|
        @cells << TableCell.new(@container, :ole_object, c)
      end
      @cells
    end

    private :cells
    
    # Returns an initialized instance of a table row
    #   * o  - the object contained in the row
    #   * container  - an instance of an IE object
    #   * how          - symbol - how we access the row
    #   * what         - what we use to access the row - id, index etc. If how is :ole_object then what is a Internet Explorer Raw Row
    def initialize(container, how, what)
      set_container container
      @how = how
      @what = what
      super nil
    end
    
    # this method iterates through each of the cells in the row. Yields a TableCell object
    def each
      locate
      0.upto(cells.length - 1) { |i| yield cells[i] }
    end
    
    # Returns an element from the row as a TableCell object
    def [](index)
      assert_exists
      if cells.length <= index
        raise UnknownCellException, "Unable to locate a cell at index #{index}" 
      end
      return cells[index]
    end
    
    # defaults all missing methods to the array of elements, to be able to
    # use the row as an array
    #        def method_missing(aSymbol, *args)
    #            return @o.send(aSymbol, *args)
    #        end
    def column_count
      locate
      cells.length
    end

    # Returns (multi-dimensional) array of the cell texts in table's row.
    #
    # Works with th, td elements, colspan, rowspan and nested tables.
    # Takes an optional parameter *max_depth*, which is by default 1
    def to_a(max_depth=1)
      assert_exists
      y = []
      @o.cells.each do |cell|
        inner_tables = cell.getElementsByTagName("TABLE")
        inner_tables.each do |inner_table|
          # make sure that the inner table is directly child for this cell
          if inner_table?(cell, inner_table)
            max_depth -= 1
            y << Table.new(@container, :ole_object, inner_table).to_a(max_depth) if max_depth >= 1
          end
        end

        if inner_tables.length == 0
          y << cell.innerText.strip
        end
      end
      y
    end

    private
    # Returns true if inner_table is direct child
    # table for cell and there's not any table-s in between
    def inner_table?(cell, inner_table)
      parent_element = inner_table.parentElement
      if parent_element.uniqueID == cell.uniqueID
        return true
      elsif parent_element.tagName == "TABLE"
        return false
      else
        return inner_table?(cell, parent_element)
      end
    end

    Watir::Container.module_eval do
      def row(how={}, what=nil)
        TableRow.new(self, how, what)
      end

      alias_method :tr, :row

      def rows(how={}, what=nil)
        TableRows.new(self, how, what)
      end

      alias_method :trs, :rows
    end
  end
  
  # this class is a table cell - when called via the Table object
  class TableCell < Element
    include Watir::Exception
    include Container

    TAG = "TD"
    
    # Returns an initialized instance of a table cell
    #   * container  - an  IE object
    #   * how        - symbol - how we access the cell
    #   * what       - what we use to access the cell - id, name index etc
    def initialize(container, how, what)
      set_container container
      @how = how
      @what = what
      super nil
    end
    
    def ole_inner_elements
      locate
      return @o.all
    end
    private :ole_inner_elements
    
    def document
      locate
      return @o
    end
    
    alias to_s text
    
    def colspan
      locate
      @o.colSpan
    end
    
    Watir::Container.module_eval do
      def cell(how={}, what=nil)
        TableCell.new(self, how, what)
      end

      alias_method :td, :cell

      def cells(how={}, what=nil)
        TableCells.new(self, how, what)
      end

      alias_method :tds, :cells
    end
  end
  
end
