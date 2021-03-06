# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "gqtp/parser"

class HeaderTest < Test::Unit::TestCase
  class EqualTest < self
    def test_true
      assert_equal(GQTP::Header.new,
                   GQTP::Header.new)
    end

    def test_false
      header_size_0 = GQTP::Header.new
      header_size_1 = GQTP::Header.new
      header_size_1.size = 1
      assert_not_equal(header_size_0, header_size_1)
    end
  end

  class InitializeTest < self
    def test_hash
      header = GQTP::Header.new(:size => 29)
      assert_equal(29, header.size)
    end

    def test_block
      header = GQTP::Header.new do |h|
        h.size = 29
      end
      assert_equal(29, header.size)
    end
  end
end
