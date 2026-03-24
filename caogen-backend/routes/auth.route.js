/**
 * Apple 登录路由
 * 支持草包 iOS/macOS/iPadOS 和草根管家 iOS 的账号互通
 */

const express = require('express');
const jwt = require('jsonwebtoken');
const NodeRSA = require('node-rsa');

// Apple 登录验证
async function verifyAppleToken(identityToken) {
    try {
        // 解析 Apple ID Token（JWT）
        const decoded = jwt.decode(identityToken, { complete: true });

        // 验证 Apple 公钥
        const response = await fetch('https://appleid.apple.com/auth/keys');
        const keys = await response.json();

        const key = keys.keys.find(k => k.kid === decoded.header.kid);

        if (!key) {
            throw new Error('无法找到 Apple 公钥');
        }

        const publicKey = NodeRSA.importKey(
            key.n,
            'der',
            'pem',
            { header: key }
        );

        // 验证 JWT
        const isValid = publicKey.verify(
            new Buffer.from(decoded.payload, 'base64'),
            decoded.signature
        );

        if (!isValid) {
            throw new Error('Apple Token 验证失败');
        }

        return {
            isValid: true,
            userIdentifier: decoded.payload.sub,
            email: decoded.payload.email,
            emailVerified: decoded.payload.email_verified || false,
            issuer: decoded.payload.iss,
            issuedAt: decoded.payload.iat,
            expiresAt: decoded.payload.exp
        };
    } catch (error) {
        throw new Error(`Apple Token 验证失败: ${error.message}`);
    }
}

// Apple 登录路由
module.exports = (app) => {
    /**
     * Apple 登录（iOS/macOS/iPadOS）
     */
    app.post('/api/auth/apple', async (req, res) => {
        try {
            const {
                identityToken,
                authorizationCode,
                userIdentifier,
                email,
                fullName
            } = req.body;

            if (!identityToken) {
                return res.status(400).json({
                    success: false,
                    error: '缺少 identityToken'
                });
            }

            // 1. 验证 Apple Token
            const appleUser = await verifyAppleToken(identityToken);

            console.log('🍎� Apple 用户信息:', appleUser);

            // 2. 检查用户是否存在
            const User = require('mongoose').model('User');
            
            let user = await User.findOne({ 
                userIdentifier: appleUser.userIdentifier 
            });

            if (!user) {
                // 新用户，创建账号
                user = new User({
                    userIdentifier: appleUser.userIdentifier,
                    email: appleUser.email,
                    emailVerified: appleUser.emailVerified,
                    fullName: fullName || '草包用户',
                    provider: 'apple',
                    platform: req.body.platform || 'ios',
                    createdAt: new Date(),
                    updatedAt: new Date()
                });

                await user.save();

                console.log('✅ 新用户创建成功:', user.email);
            } else {
                // 更新用户信息
                if (appleUser.email && !user.email) {
                    user.email = appleUser.email;
                    user.emailVerified = appleUser.emailVerified;
                }

                if (fullName && !user.fullName) {
                    user.fullName = fullName;
                }

                if (req.body.platform) {
                    user.platform = req.body.platform;
                }

                user.updatedAt = new Date();
                await user.save();

                console.log('🔄 用户信息更新:', user.email);
            }

            // 3. 检查是否需要关联草包账号
            if (req.body.caobaoUserIdentifier) {
                user.caobaoUserIdentifier = req.body.caobaoUserIdentifier;
                user.hasCaobaoLinked = true;
                user.updatedAt = new Date();
                await user.save();

                console.log('🔗 已关联草包账号');
            }

            // 4. 检查是否需要关联草根管家账号
            if (req.body.caogenUserIdentifier) {
                user.caogenUserIdentifier = req.body.caogenUserIdentifier;
                user.hasCaogenLinked = true;
                user.updatedAt = new Date();
                await user.save();

                console.log('🔗 已关联草根管家账号');
            }

            // 5. 生成 JWT Token
            const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

            const token = jwt.sign(
                {
                    userId: user._id.toString(),
                    userIdentifier: user.userIdentifier,
                    platform: req.body.platform || 'ios'
                },
                JWT_SECRET,
                { expiresIn: '30d' }
            );

            // 6. 生成 Session Token
            const sessionToken = jwt.sign(
                {
                    userId: user._id.toString(),
                    deviceId: req.body.deviceId || 'unknown',
                    platform: req.body.platform || 'ios'
                },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            // 7. 创建 Session
            const Session = require('mongoose').model('Session');
            const session = new Session({
                userId: user._id,
                sessionToken,
                deviceId: req.body.deviceId || 'unknown',
                platform: req.body.platform || 'ios',
                ipAddress: req.ip,
                createdAt: new Date(),
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
            });

            await session.save();

            console.log('✅ Session 已创建');

            res.json({
                success: true,
                message: '登录成功',
                user: {
                    id: user._id,
                    email: user.email,
                    fullName: user.fullName,
                    userIdentifier: user.userIdentifier,
                    provider: 'apple',
                    platform: user.platform,
                    hasCaobaoLinked: user.hasCaobaoLinked || false,
                    caobaoUserIdentifier: user.caobaoUserIdentifier || null,
                    hasCaogenLinked: user.hasCaogenLinked || false,
                    caogenUserIdentifier: user.caogenUserIdentifier || null
                },
                token,
                sessionToken,
                expiresAt: user.expiresAt || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
            });

        } catch (error) {
            console.error('❌ Apple 登录失败:', error);
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    /**
     * 游客登录（用于测试）
     */
    app.post('/api/auth/guest', async (req, res) => {
        try {
            const deviceId = req.body.deviceId || 'guest-' + Date.now();
            const platform = req.body.platform || 'ios';

            console.log('👤 游客登录:', deviceId);

            // 1. 查找或创建游客账号
            const User = require('mongoose').model('User');
            
            let user = await User.findOne({ userIdentifier: `guest-${deviceId}` });

            if (!user) {
                user = new User({
                    userIdentifier: `guest-${deviceId}`,
                    email: null,
                    emailVerified: false,
                    fullName: '游客',
                    provider: 'guest',
                    platform,
                    createdAt: new Date(),
                    updatedAt: new Date()
                });

                await user.save();

                console.log('✅ 游客账号创建成功');
            }

            // 2. 生成 Token
            const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

            const token = jwt.sign(
                {
                    userId: user._id.toString(),
                    userIdentifier: user.userIdentifier,
                    platform
                },
                JWT_SECRET,
                { expiresIn: '30d' }
            );

            res.json({
                success: true,
                message: '游客登录成功',
                user: {
                    id: user._id,
                    email: user.email,
                    fullName: user.fullName,
                    userIdentifier: user.userIdentifier,
                    provider: 'guest',
                    platform
                },
                token,
                expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
            });

        } catch (error) {
            console.error('❌ 游客登录失败:', error);
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    /**
     * 关联账号
     */
    app.post('/api/auth/link', async (req, res) => {
        try {
            const {
                userId,
                targetUserIdentifier,
                targetPlatform
            } = req.body;

            if (!userId || !targetUserIdentifier) {
                return res.status(400).json({
                    success: false,
                    error: '缺少必要参数'
                });
            }

            const User = require('mongoose').model('User');
            const user = await User.findById(userId);

            if (!user) {
                return res.status(404).json({
                    success: false,
                    error: '用户不存在'
                });
            }

            // 更新关联信息
            if (targetPlatform === 'caobao') {
                user.caobaoUserIdentifier = targetUserIdentifier;
                user.hasCaobaoLinked = true;
            } else if (targetPlatform === 'caogen') {
                user.caogenUserIdentifier = targetUserIdentifier;
                user.hasCaogenLinked = true;
            }

            user.updatedAt = new Date();
            await user.save();

            console.log(`🔗 已关联账号: ${targetPlatform}`);

            res.json({
                success: true,
                message: '账号关联成功'
            });

        } catch (error) {
            console.error('❌ 账号关联失败:', error);
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });

    /**
     * 检查 Token
     */
    app.get('/api/auth/me', async (req, res) => {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');

            if (!token) {
                return res.status(401).json({
                    success: false,
                    error: '缺少认证Token'
                });
            }

            const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
            const decoded = jwt.verify(token, JWT_SECRET);

            const User = require('mongoose').model('User');
            const user = await User.findById(decoded.userId);

            if (!user) {
                return res.status(404).json({
                    success: false,
                    error: '用户不存在'
                });
            }

            res.json({
                success: true,
                user: {
                    id: user._id,
                    email: user.email,
                    fullName: user.fullName,
                    userIdentifier: user.userIdentifier,
                    provider: user.provider,
                    platform: user.platform,
                    hasCaobaoLinked: user.hasCaobaoLinked || false,
                    caobaoUserIdentifier: user.caobaoUserIdentifier || null,
                    hasCaogenLinked: user.hasCaogenLinked || false,
                    caogenUserIdentifier: user.caogenUserIdentifier || null
                }
            });

        } catch (error) {
            console.error('❌ Token 验证失败:', error);
            res.status(401).json({
                success: false,
                error: 'Token 无效'
            });
        }
    });

    /**
     * 注销
     */
    app.post('/api/auth/logout', async (req, res) => {
        try {
            const userId = req.body.userId;

            // 删除 Session
            const Session = require('mongoose').model('Session');
            await Session.deleteMany({ userId });

            console.log('✅ 用户已注销:', userId);

            res.json({
                success: true,
                message: '注销成功'
            });

        } catch (error) {
            console.error('❌ 注销失败:', error);
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    });
};
