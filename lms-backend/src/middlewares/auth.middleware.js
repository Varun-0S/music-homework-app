const jwt = require("jsonwebtoken");

module.exports = (roles) => {
    return (req, res, next) => {
        try {
            const token = req.header("Authorization")?.replace("Bearer ", "");
            if (!token) {
                return res.status(401).json({ message: "No token, authorization denied" });
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = decoded;

            console.log("Decoded user:", decoded);

            
            if (roles) {
                const allowedRoles = Array.isArray(roles) ? roles : [roles];
                if (!allowedRoles.includes(decoded.role)) {
                    return res.status(403).json({ message: "Access denied" });
                }
            }

            next();
        } catch (err) {
            console.error("Auth Middleware Error:", err.message);
            res.status(401).json({ message: "Token is not valid" });
        }
    };
};
