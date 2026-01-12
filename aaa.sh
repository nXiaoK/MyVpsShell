

    @Override
    public BidScoreVo queryByTkbm(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }        if (StringUtils.isEmpty(bjbh)) {
                     return JGBAjaxResult.error("报建编号不能为空");
                 }
        EvaluationClause queryTkbm = new EvaluationClause();
        queryTkbm.setClauseCode(scoreQuery.getTkbm());
        EvaluationResult evaluationResult = evaluationResultService.selectEvaluationResultList(params).stream().findFirst().orElse(null);
        return null;
    }


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

dfafasfdfafdsfsf

    public JGBAjaxResult queryStatus(@RequestBody BidQueryStatus queryStatus) {
        JGBAjaxResult valid = validateBaseParams(queryStatus.getBdh(), queryStatus.getBjbh(), queryStatus.getZbid());
        if (valid != null) {
            return valid;
        }

        BidStatusVo vo = bidExternalInterfaceService.queryStatus(queryStatus);
        return successOrFail(vo);
    }

    @Override
    public BidScoreDetailVo query(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }


        sdfafasfsfd
        List<ScoreDetail> scoreDetails = evaluationResultService.selectScoreDetailListByProjectId(projectId);
        BidScoreDetailVo detailVo = new BidScoreDetailVo();
        BeanUtils.copyProperties(scoreQuery, detailVo);
        detailVo.setScoreDetails(scoreDetails);
        detailVo.setTimestamp(DateUtils.getNowDate().getTime());
        return detailVo;
    }
