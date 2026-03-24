// 生成 Siri Shortcuts 配置文件
// 运行: node generate-shortcut.js

const fs = require('fs');
const path = require('path');

// 配置
const config = {
  shortcutName: '草根管家',
  description: '通过 Siri 调用草根管家 AI 助手',
  // 修改为你的服务器地址
  apiUrl: 'http://YOUR_IP_OR_DOMAIN:3001/api/chat',
  voicePhrase: '嘿，草根',
  icon: {
    glyph: '🌾',
    color: '#4CAF50'
  }
};

// 生成快捷指令配置（简化版）
const shortcutConfig = {
  WFWorkflowMinimumClientVersion: 900,
  WFWorkflowMinimumClientVersionString: '900',
  WFWorkflowIcon: {
    WFWorkflowIconStartColor: config.icon.color,
    WFWorkflowIconGlyphNumber: 61440
  },
  WFWorkflowOutputContentItemClasses: [],
  WFWorkflowActions: [
    {
      WFWorkflowActionIdentifier: 'is.workflow.actions.detect.text',
      WFWorkflowActionParameters: {
        WFInputType: 0,
        WFAskForPrompt: true,
        WFAskForPromptTitle: '对草根管家说',
        WFAskForPromptDefault: '帮我写个周报'
      }
    },
    {
      WFWorkflowActionIdentifier: 'is.workflow.actions.getcontents',
      WFWorkflowActionParameters: {
        WFURL: config.apiUrl,
        WFHTTPMethod: 1, // POST
        WFHTTPHeaders: {
          Value: {
            WFDictionaryFieldValueItems: [
              {
                WFItemType: 0,
                WFKey: {
                  Value: {
                    string: 'Content-Type',
                    attachmentsByRange: {}
                  },
                  WFSerializationType: 'WFTextTokenString'
                },
                WFValue: {
                  Value: {
                    string: 'application/json',
                    attachmentsByRange: {}
                  },
                  WFSerializationType: 'WFTextTokenString'
                }
              }
            ]
          },
          WFSerializationType: 'WFDictionaryFieldValue'
        },
        WFHTTPRequestBodyType: 0,
        WFHTTPRequestBody: {
          Value: {
            string: JSON.stringify({
              message: '{{听写}}'
            }),
            attachmentsByRange: {
              '{{听写}}': {
                Type: 'Variable',
                VariableName: '听写'
              }
            }
          },
          WFSerializationType: 'WFTextTokenString'
        }
      }
    },
    {
      WFWorkflowActionIdentifier: 'is.workflow.actions.getdictionaryvalue',
      WFWorkflowActionParameters: {
        WFDictionaryKey: {
          Value: {
            string: 'data',
            attachmentsByRange: {}
          },
          WFSerializationType: 'WFTextTokenString'
        }
      }
    },
    {
      WFWorkflowActionIdentifier: 'is.workflow.actions.speaktext',
      WFWorkflowActionParameters: {
        WFText: {
          Value: {
            string: '{{获取词典值}}',
            attachmentsByRange: {
              '{{获取词典值}}': {
                Type: 'Variable',
                VariableName: '获取词典值'
              }
            }
          },
          WFSerializationType: 'WFTextTokenString'
        },
        WFSpeakTextRate: 0.5,
        WFSpeakTextPitch: 1
      }
    }
  ],
  WFWorkflowTypes: ['NCWidget', 'WatchKit']
};

// 保存文件
const outputPath = path.join(__dirname, '草根管家.shortcut');
const plistContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>WFWorkflowMinimumClientVersion</key>
  <integer>${shortcutConfig.WFWorkflowMinimumClientVersion}</integer>
  <key>WFWorkflowMinimumClientVersionString</key>
  <string>${shortcutConfig.WFWorkflowMinimumClientVersionString}</string>
  <key>WFWorkflowIcon</key>
  <dict>
    <key>WFWorkflowIconStartColor</key>
    <string>${shortcutConfig.WFWorkflowIcon.WFWorkflowIconStartColor}</string>
  </dict>
  <key>WFWorkflowActions</key>
  <array>
    <!-- 动作配置 -->
  </array>
</dict>
</plist>`;

console.log('\n========================================');
console.log('  📱 生成 Siri Shortcuts 配置');
console.log('========================================\n');

console.log(`快捷指令名称: ${config.shortcutName}`);
console.log(`语音短语: ${config.shortcutName}`);
console.log(`API 地址: ${config.apiUrl}\n`);

// 注意：完整的 .shortcut 文件需要使用 plist 格式
// 这里只是一个示例，实际需要使用更复杂的格式

console.log('========================================');
console.log('  ⚠️  说明');
console.log('========================================\n');
console.log('1. iOS 的 .shortcut 文件格式是专有的 plist 格式');
console.log('2. 完整的 .shortcut 文件需要使用 Apple 的工具生成');
console.log('3. 建议使用「快捷指令」App 手动配置（见 README.md）');
console.log('4. 或者使用 iCloud 共享快捷指令功能\n');

console.log('========================================');
console.log('  ✅ 下一步');
console.log('========================================\n');
console.log('1. 修改 config.apiUrl 为你的服务器地址');
console.log('2. 参考 README.md 中的「Siri 配置指南」');
console.log('3. 在 iPhone 上打开「快捷指令」App');
console.log('4. 按照步骤手动创建快捷指令\n');

console.log('========================================\n');
