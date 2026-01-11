/**
 * 外部接口 Controller
 * 优化点
 * 1 抽取必填参数校验 统一返回
 * 2 抽取统一成功失败响应 统一文案
 * 3 保持原有接口路径与返回结构不变
 */
@RestController
@RequestMapping("/bid")
public class BidExternalInterfaceController {

    private static final String MSG_SUCCESS = "段落评分查询成功";
    private static final String MSG_FAIL = "段落评分查询失败";

    @Resource
    private BidExternalInterfaceService bidExternalInterfaceService;

    /**
     * 查询评分状态接口
     */
    @PostMapping("/queryStatus")
    public JGBAjaxResult queryStatus(@RequestBody BidQueryStatus queryStatus) {
        JGBAjaxResult valid = validateBaseParams(queryStatus.getBdh(), queryStatus.getBjbh(), queryStatus.getZbid());
        if (valid != null) {
            return valid;
        }

        BidStatusVo vo = bidExternalInterfaceService.queryStatus(queryStatus);
        return successOrFail(vo);
    }

    /**
     * 查询单个条款编码评分接口
     */
    @PostMapping("/score/queryByTkbm")
    public JGBAjaxResult queryByTkbm(@RequestBody BidScoreQuery scoreQuery) {
        JGBAjaxResult valid = validateBaseParams(scoreQuery.getBdh(), scoreQuery.getBjbh(), scoreQuery.getZbid());
        if (valid != null) {
            return valid;
        }
        if (StringUtils.isEmpty(scoreQuery.getTkbm())) {
            return JGBAjaxResult.error("条款编码不能为空");
        }

        BidScoreVo vo = bidExternalInterfaceService.queryByTkbm(scoreQuery);
        return successOrFail(vo);
    }

    /**
     * 查询AI评分结果接口
     */
    @PostMapping("/score/query")
    public JGBAjaxResult query(@RequestBody BidScoreQuery scoreQuery) {
        JGBAjaxResult valid = validateBaseParams(scoreQuery.getBdh(), scoreQuery.getBjbh(), scoreQuery.getZbid());

        BidScoreDetailVo vo = bidExternalInterfaceService.query(scoreQuery);
        return successOrFail(vo);
    }


    /**
     * 统一的成功失败返回
     * data 不为 null 返回 success
     * data 为 null 返回 error
     */
    private JGBAjaxResult successOrFail(Object data) {
        if (data != null) {
            return JGBAjaxResult.success(MSG_SUCCESS, data);
        }
        return JGBAjaxResult.error(MSG_FAIL);
    }
}
