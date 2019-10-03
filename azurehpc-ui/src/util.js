Object.byString = function (o, s) {
    s = s.replace(/\[(\w+)\]/g, ".$1"); // convert indexes to properties
    s = s.replace(/^\./, ""); // strip a leading dot
    var a = s.split(".");
    for (var i = 0, n = a.length; i < n; ++i) {
        var k = a[i];
        if (k in o) {
            o = o[k];
        } else {
            return;
        }
    }
    return o;
};

function read_value(config, path) {
    var v = Object.byString(config, path);
    while (typeof v === "string" && v.startsWith("variables.")) {
        v = Object.byString(config, v);
    }
    return v;
}

export default read_value;