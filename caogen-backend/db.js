/**
 * Mongoose 模型定义
 */

const mongoose = require('mongoose');

// 连接 MongoDB
const connectDB = async () => {
    try {
        const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/caogen';
        
        await mongoose.connect(mongoURI);
        console.log('✅ MongoDB 连接成功');
    } catch (error) {
        console.error('❌ MongoDB 连接失败:', error);

        // 降级到内存存储
        console.log('⚠️ 降级到内存存储模式');
        console.log('⚠️ 注意：数据将在重启后丢失');
    }
};

module.exports = { connectDB };
