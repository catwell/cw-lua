local bit = require("bit")
local band,rshift = bit.band,bit.rshift
local structures = require "structures"

  -- p-notes:
  -- B and C are 9 bits: 1 bit is_register? + 8
  -- B and C are reversed!!! (A C B)

  -- Notes:
  -- (*) In OP_CALL, if (B == 0) then B = top. If (C == 0), then `top' is
  -- set to last_result+1, so next open instruction (OP_CALL, OP_RETURN,
  -- OP_SETLIST) may use `top'.

  -- (*) In OP_VARARG, if (B == 0) then use actual number of varargs and
  -- set top (like in OP_CALL with C == 0).

  -- (*) In OP_RETURN, if (B == 0) then return up to `top'.

  -- (*) In OP_SETLIST, if (B == 0) then B = `top'; if (C == 0) then next
  -- 'instruction' is EXTRAARG(real C).

  -- (*) In OP_LOADKX, the next 'instruction' is always EXTRAARG.

  -- (*) For comparisons, A specifies what condition the test should accept
  -- (true or false).

  -- (*) All `skips' (pc++) assume that next instruction is a jump.

local OP = structures.bimap(0,{
  [0] = "MOVE", -- |A B|   R(A) := R(B)
  "LOADK", -- |A Bx|   R(A) := Kst(Bx)
  "LOADKX", -- |A|   R(A) := Kst(extra arg)
  "LOADBOOL", -- |A B C|   R(A) := (Bool)B; if (C) pc++
  "LOADNIL", -- |A B|   R(A), R(A+1), ..., R(A+B) := nil
  "GETUPVAL", -- |A B|   R(A) := UpValue[B]
  "GETTABUP", -- |A B C|   R(A) := UpValue[B][RK(C)]
  "GETTABLE", -- |A B C|   R(A) := R(B)[RK(C)]
  "SETTABUP", -- |A B C|   UpValue[A][RK(B)] := RK(C)
  "SETUPVAL", -- |A B|   UpValue[B] := R(A)
  "SETTABLE", -- |A B C|   R(A)[RK(B)] := RK(C)
  "NEWTABLE", -- |A B C|   R(A) := {} (size = B,C)
  "SELF", -- |A B C|   R(A+1) := R(B); R(A) := R(B)[RK(C)]
  "ADD", -- |A B C|   R(A) := RK(B) + RK(C)
  "SUB", -- |A B C|   R(A) := RK(B) - RK(C
  "MUL", -- |A B C|   R(A) := RK(B) * RK(C)
  "DIV", -- |A B C|   R(A) := RK(B) / RK(C)
  "MOD", -- |A B C|   R(A) := RK(B) % RK(C)
  "POW", -- |A B C|   R(A) := RK(B) ^ RK(C)
  "UNM", -- |A B|   R(A) := -R(B)
  "NOT", -- |A B|   R(A) := not R(B)
  "LEN", -- |A B|   R(A) := length of R(B)
  "CONCAT", -- |A B C|   R(A) := R(B).. ... ..R(C)
  "JMP", -- |A sBx|   pc+=sBx; if (A) close all upvalues >= R(A) + 1
  "EQ", -- |A B C|   if ((RK(B) == RK(C)) ~= A) then pc++
  "LT", -- |A B C|   if ((RK(B) <  RK(C)) ~= A) then pc++
  "LE", -- |A B C|   if ((RK(B) <= RK(C)) ~= A) then pc++
  "TEST", -- |A C|   if not (R(A) <=> C) then pc++
  "TESTSET", -- |A B C|   if (R(B) <=> C) then R(A) := R(B) else pc++
  "CALL", -- |A B C|   R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  "TAILCALL", -- |A B C|   return R(A)(R(A+1), ... ,R(A+B-1))
  "RETURN", -- |A B|   return R(A), ... ,R(A+B-2)  (see note)
  "FORLOOP", -- |A sBx|   R(A)+=R(A+2); if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
  "FORPREP", -- |A sBx|   R(A)-=R(A+2); pc+=sBx
  "TFORCALL", -- |A C|   R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
  "TFORLOOP", -- |A sBx|   if R(A+1) ~= nil then { R(A)=R(A+1); pc += sBx }
  "SETLIST", -- |A B C|   R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
  "CLOSURE", -- |A Bx|   R(A) := closure(KPROTO[Bx])
  "VARARG", -- |A B|   R(A), R(A+1), ..., R(A+B-2) = vararg
  "EXTRAARG", -- |Ax|   extra (larger) argument for previous opcode
})

local get_BC_reg_val = function(x)
  if band(x,0x100) > 0 then -- register
    return tonumber(-1-(band(x,0xff)))
  else
    return tonumber(x)
  end
end

local get_A = function(x)
  return tonumber(band(rshift(x,6),0xff))
end

local get_B = function(x)
  return get_BC_reg_val(band(rshift(x,23),0x1ff))
end

local get_C = function(x)
  return get_BC_reg_val(band(rshift(x,14),0x1ff))
end

local get_Axk = function(x)
  return -1-tonumber(band(rshift(x,6),0x3ffffff))
end

local get_Bx = function(x)
  return tonumber(band(rshift(x,14),0x3ffff))
end

local get_Bxk = function(x)
  return -1-tonumber(band(rshift(x,14),0x3ffff))
end

local get_sBx = function(x)
  return tonumber(band(rshift(x,14),0x3ffff))-0x1ffff
end

local fmt_1 = "%-9s\t%d"
local fmt_2 = fmt_1 .. " %d"
local fmt_3 = fmt_2 .. " %d"

local ser = {
  AB = function(opname)
    return function(x)
      return string.format(fmt_2,opname,get_A(x),get_B(x))
    end
  end,
  AC = function(opname)
    return function(x)
      return string.format(fmt_2,opname,get_A(x),get_C(x))
    end
  end,
  ABx = function(opname)
    return function(x)
      return string.format(fmt_2,opname,get_A(x),get_Bx(x))
    end
  end,
  ABxk = function(opname)
    return function(x)
      return string.format(fmt_2,opname,get_A(x),get_Bxk(x))
    end
  end,
  AsBx = function(opname)
    return function(x)
      return string.format(fmt_2,opname,get_A(x),get_sBx(x))
    end
  end,
  A = function(opname)
    return function(x)
      return string.format(fmt_1,opname,get_A(x))
    end
  end,
  Axk = function(opname)
    return function(x)
      return string.format(fmt_1,opname,get_Axk(x))
    end
  end,
  ABC = function(opname)
    return function(x)
      return string.format(fmt_3,opname,get_A(x),get_B(x),get_C(x))
    end
  end,
}

local ops = {
  AB =   { "MOVE","LOADNIL","GETUPVAL","SETUPVAL","UNM","NOT","LEN","TEST",
           "RETURN","VARARG" },
  AC =   { "TFORCALL" },
  AsBx = { "JMP","FORLOOP","FORPREP","TFORLOOP" },
  A =    { "LOADKX" },
  ABx =  { "CLOSURE" },
  ABxk = { "LOADK" },
  Axk =   { "EXTRAARG" },
  ABC =  { "LOADBOOL","GETTABUP","GETTABLE","SETTABUP","SETTABLE","NEWTABLE",
           "SELF","ADD","SUB","MUL","DIV","MOD","POW","CONCAT","EQ","LT","LE",
           "TESTSET","CALL","TAILCALL","SETLIST" },
}

local string_serializers = {}
for k,v in pairs(ops) do
  for i=1,#v do
    string_serializers[OP[v[i]]] = ser[k](v[i])
  end
end

local to_string = function(x)
  local op = band(x,0x3f)
  return string_serializers[op](x)
end

return {
  to_string = to_string,
}
