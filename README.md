# decolonize

Tessel examples using Lua directly (i.e. not using
[Colony](https://github.com/tessel/colony-compiler)).

To push those to the Tessel, the easiest way is to patch `bundle.js`
like this:

           try {
             var source = fs.readFileSync(fullpath, 'utf-8');
    -        var res = colonyCompiler.colonize(source);
    +        var res;
    +        if (f.match(/\.lua.js$/)) {
    +          res = {"source": source}
    +        }
    +        else {
    +          res = colonyCompiler.colonize(source);
    +        }
           } catch (e) {
             if (!(e instanceof SyntaxError)) {
               throw e;
             }

If you are looking for a full-featured way to use Lua on Tessel,
check out [lua-tessel](https://github.com/paulcuth/lua-tessel/).
